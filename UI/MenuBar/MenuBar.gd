extends HBoxContainer


enum ProjectOptions {
	OPEN_CFG,
	SAVE_CFG
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
	
	# Connect item pressed with callback
	project_options.index_pressed.connect(
		func(idx): project_options.get_item_metadata(idx).call())
