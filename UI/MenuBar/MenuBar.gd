extends HBoxContainer


var layer_configurator: Configurator setget set_layer_configurator


enum ProjectOptions {
	PRE_GPKG
}


func _ready():
	$ProjectButton.get_popup().add_item("Open a preconfigured GeoPackage ...", ProjectOptions.PRE_GPKG)
	$ProjectButton.get_popup().set_item_metadata(ProjectOptions.PRE_GPKG, "_pop_gpkg_menu")
	
	$ProjectButton.get_popup().connect("index_pressed", self, "_on_proj_menu_pressed")


func set_layer_configurator(lc):
	layer_configurator = lc
	layer_configurator.connect("geodata_invalid", self, "_pop_gpkg_menu")
	$ProjectButton/GeopackageFileDialog.connect("file_selected", layer_configurator, "load_gpkg")


func _pop_gpkg_menu():
	$ProjectButton/GeopackageFileDialog.popup_centered()


func _on_proj_menu_pressed(idx: int):
	call($ProjectButton.get_popup().get_item_metadata(idx))
