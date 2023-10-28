extends HBoxContainer


enum ProjectOptions {
	OPEN_CFG,
	SAVE_CFG,
	VEGETATION_DETAILS,
}


func _ready():
	var project_options = $ProjectButton.get_popup()
	
	# Add options and store callback functions in metadata to call when 
	# the option is pressed
	project_options.add_item("Open a .ll config...", ProjectOptions.OPEN_CFG)
	project_options.set_item_metadata(ProjectOptions.OPEN_CFG, 
		$ProjectButton/OpenCfg.popup_centered)
	project_options.add_item("Save a .ll config...", ProjectOptions.SAVE_CFG)
	project_options.set_item_metadata(ProjectOptions.SAVE_CFG, 
		$ProjectButton/SaveCfg.popup_centered)
	project_options.add_item("Set vegetation paths...", ProjectOptions.VEGETATION_DETAILS)
	project_options.set_item_metadata(ProjectOptions.VEGETATION_DETAILS,
		$ProjectButton/VegetationDetails.popup_centered)
	
	# Conenct selecting an ll file with opening and applying the config
	$ProjectButton/OpenCfg.file_selected.connect(func(path):
		var ll_file_access = LLFileAccess.open(path)
		if ll_file_access == null:
			logger.error("Could not load config at " + path)
			return
			
		ll_file_access.apply(Vegetation, Layers, Scenarios, GameSystem)
	)
	
	# Connect selecting a file location for ll with serialization of current state
	$ProjectButton/SaveCfg.file_selected.connect(func(path):
		var ll_file_access = LLFileAccess.open(path)
		ll_file_access.save()
	)
	
	# Setup vegetation logic
	$ProjectButton/VegetationDetails.confirmed.connect(_on_set_vegetation_paths)
	# If one path is selected try selecting all from the same dir (else this is a lot of work)
	$ProjectButton/VegetationDetails/VBox/Paths/Densities.file_selected.connect(
		_try_set_all_paths)
	$ProjectButton/VegetationDetails/VBox/Paths/Plants.file_selected.connect(
		_try_set_all_paths)
	$ProjectButton/VegetationDetails/VBox/Paths/Groups.file_selected.connect(
		_try_set_all_paths)
	$ProjectButton/VegetationDetails/VBox/Paths/Textures.file_selected.connect(
		_try_set_all_paths)
	# Set initial plant extent
	$ProjectButton/VegetationDetails/VBox/Config/SpinBox.value = Vegetation.plant_extent_factor
	# Changing plant extent should update the actual extent
	$ProjectButton/VegetationDetails/VBox/Config/SpinBox.value_changed.connect(
		func(val): Vegetation.plant_extent_factor = val)
	
	# Connect item pressed with callback
	project_options.index_pressed.connect(
		func(idx): project_options.get_item_metadata(idx).call())


func _on_set_vegetation_paths():
	Vegetation.load_data_from_csv(
		$ProjectButton/VegetationDetails/VBox/Paths/Plants/FileName.text,
		$ProjectButton/VegetationDetails/VBox/Paths/Groups/FileName.text,
		$ProjectButton/VegetationDetails/VBox/Paths/Densities/FileName.text,
		$ProjectButton/VegetationDetails/VBox/Paths/Textures/FileName.text
	)


func _try_set_all_paths(path: String):
	for csv in ["densities", "groups", "plants", "textures"]:
		if csv + ".csv" in DirAccess.get_files_at(path.get_base_dir()):
			var node = get_node("ProjectButton/SetVegetationPaths/Grid/{}/FileName"
				.format([csv.capitalize()], "{}"))
			node.text = "{}/{}.csv".format([path.get_base_dir(), csv], "{}")
