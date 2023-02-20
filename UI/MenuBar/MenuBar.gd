extends HBoxContainer


var layer_configurator: Configurator :
	get:
		return layer_configurator
	set(lc):
		layer_configurator = lc
		lc.configuration_invalid.connect($ProjectButton/OpenCfg.popup_centered)
		$ProjectButton/OpenCfg.file_selected.connect(lc.load_ll_json)
		$ProjectButton/SaveCfg.file_selected.connect(lc.save_ll_json)
		
		# If we missed the invalid load signal, pop the menu now
		if not lc.has_loaded:
			$ProjectButton/OpenCfg.popup_centered()


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
	
	# Connect item pressed with callback
	project_options.index_pressed.connect(
		func(idx): project_options.get_item_metadata(idx).call())
