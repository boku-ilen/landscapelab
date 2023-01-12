extends HBoxContainer


var layer_configurator: Configurator :
	get:
		return layer_configurator
	set(lc):
		layer_configurator = lc
		lc.configuration_invalid.connect(_pop_gpkg_menu)
		$ProjectButton/FileDialog.file_selected.connect(lc.load_ll_json)
		
		# If we missed the invalid load signal, pop the menu now
		if not lc.has_loaded:
			_pop_gpkg_menu()


enum ProjectOptions {
	PRE_GPKG
}


func _ready():
	$ProjectButton.get_popup().add_item("Open a .ll config...", ProjectOptions.PRE_GPKG)
	$ProjectButton.get_popup().set_item_metadata(ProjectOptions.PRE_GPKG, "_pop_gpkg_menu")
	
	$ProjectButton.get_popup().index_pressed.connect(_on_proj_menu_pressed)


func _pop_gpkg_menu():
	$ProjectButton/FileDialog.popup_centered()


func _on_proj_menu_pressed(idx: int):
	call($ProjectButton.get_popup().get_item_metadata(idx))
