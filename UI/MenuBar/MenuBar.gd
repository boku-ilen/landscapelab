extends HBoxContainer


var layer_configurator: Configurator setget set_layer_configurator


func set_layer_configurator(lc):
	layer_configurator = lc
	layer_configurator.connect("geodata_invalid", self, "_pop_gpkg_menu")
	$ProjectButton/GeopackageFileDialog.connect("file_selected", layer_configurator, "load_gpkg")


func _pop_gpkg_menu():
	$ProjectButton/GeopackageFileDialog.popup_centered()
