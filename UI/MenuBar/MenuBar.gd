extends HBoxContainer


var layer_configurator: Configurator :
	get:
		return layer_configurator # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_layer_configurator


enum ProjectOptions {
	PRE_GPKG
}


func _ready():
	$ProjectButton.get_popup().add_item("Open a preconfigured GeoPackage ...", ProjectOptions.PRE_GPKG)
	$ProjectButton.get_popup().set_item_metadata(ProjectOptions.PRE_GPKG, "_pop_gpkg_menu")
	
	$ProjectButton.get_popup().connect("index_pressed",Callable(self,"_on_proj_menu_pressed"))


func set_layer_configurator(lc):
	layer_configurator = lc
	lc.connect("geodata_invalid",Callable(self,"_pop_gpkg_menu"))
	$ProjectButton/GeopackageFileDialog.connect("file_selected",Callable(lc,"load_gpkg"))


func _pop_gpkg_menu():
	$ProjectButton/GeopackageFileDialog.popup_centered()


func _on_proj_menu_pressed(idx: int):
	call($ProjectButton.get_popup().get_item_metadata(idx))
