extends HBoxContainer


enum ProjectOptions {
	OPEN_CFG,
	SAVE_CFG,
	SET_VEGETATION_PATHS
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
	project_options.add_item("Set vegetation paths...", ProjectOptions.SET_VEGETATION_PATHS)
	project_options.set_item_metadata(ProjectOptions.SET_VEGETATION_PATHS,
		$ProjectButton/SetVegetationPaths.popup_centered)
	
	$ProjectButton/OpenCfg.file_selected.connect(func(path):
		var ll_file_access = LLFileAccess.open(path)
		if ll_file_access == null:
			logger.error("Could not load config at " + path)
			return
			
		ll_file_access.apply(Vegetation, Layers, Scenarios)
	)
	$ProjectButton/SaveCfg.file_selected.connect(func(path):
		var ll_file_access = LLFileAccess.open(path)
		ll_file_access.save()
	)
	$ProjectButton/SetVegetationPaths.confirmed.connect(_on_set_vegetation_paths)
	$ProjectButton/SetVegetationPaths/Grid/Densities.file_selected.connect(
		_try_set_all_paths
	)
	$ProjectButton/SetVegetationPaths/Grid/Plants.file_selected.connect(
		_try_set_all_paths
	)
	$ProjectButton/SetVegetationPaths/Grid/Groups.file_selected.connect(
		_try_set_all_paths
	)
	$ProjectButton/SetVegetationPaths/Grid/Textures.file_selected.connect(
		_try_set_all_paths
	)
	
	# Connect item pressed with callback
	project_options.index_pressed.connect(
		func(idx): project_options.get_item_metadata(idx).call())


func _on_set_vegetation_paths():
	Vegetation.load_data_from_csv(
		$ProjectButton/SetVegetationPaths/Grid/Plants/FileName.text,
		$ProjectButton/SetVegetationPaths/Grid/Groups/FileName.text,
		$ProjectButton/SetVegetationPaths/Grid/Densities/FileName.text,
		$ProjectButton/SetVegetationPaths/Grid/Textures/FileName.text
	)


func _try_set_all_paths(path: String):
	for csv in ["densities", "groups", "plants", "textures"]:
		if csv + ".csv" in DirAccess.get_files_at(path.get_base_dir()):
			var node = get_node("ProjectButton/SetVegetationPaths/Grid/{}/FileName"
				.format([csv.capitalize()], "{}"))
			node.text = "{}/{}.csv".format([path.get_base_dir(), csv], "{}")
