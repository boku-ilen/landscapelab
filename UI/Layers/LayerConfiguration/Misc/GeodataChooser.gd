extends VBoxContainer


export var show_raster_layers: bool = true
export var show_feature_layer: bool = true

onready var file_dialog = get_node("FileChooser/Button/FileDialog")
onready var file_name = get_node("FileChooser/FileName")
onready var options = get_node("OptionButton")

# For geodot there is a differentiation between datasets and single files ...
var geo_dataset_extensions = [".shp", ".gpkg"]


func _ready():
	file_dialog.connect("file_selected", self, "_file_selected")
	file_name.connect("text_changed", self, "_check_path")


func _check_path():
	if is_current_file_dataset():
		var dataset = Geodot.get_dataset(file_name.text)
		if dataset.is_valid():
			_fill_options([], 0, true) # Empty all entries list
			var idx: int = 0
			if show_raster_layers:
				idx = _fill_options(dataset.get_raster_layers(), idx)
			if show_feature_layer:
				_fill_options(dataset.get_feature_layers(), idx)
			options.visible = true
		else:
			_fill_options([], 0, true) # Empty all entries list
			options.visible = false


func _file_selected(which: String):
	file_name.text = which
	_check_path()


# As filling the options with two different types of layers (feature and raster)
# the idx has to be assigned manually to fit the position in the list.
func _fill_options(which: Array, start_idx: int = 0, clear = false) -> int:
	if clear: options.clear()
	for option in which:
		options.add_item(option.resource_name)
	
	return start_idx


func is_current_file_dataset():
	return "." + file_name.text.get_extension() in geo_dataset_extensions


func get_geo_layer(is_raster: bool = true):
	if is_current_file_dataset():
		var sub_layer_name = $OptionButton.get_item_text($OptionButton.get_selected_id())
		var dataset = Geodot.get_dataset(file_name.text)
		if is_raster:
			var raster_layer = RasterLayer.new()
			raster_layer.geo_raster_layer = dataset.get_raster_layer(sub_layer_name)
			raster_layer.name = raster_layer.geo_raster_layer.resource_name
			return raster_layer
		else:
			var feature_layer = FeatureLayer.new()
			feature_layer.geo_feature_layer = dataset.get_raster_layer(sub_layer_name)
			feature_layer.name = feature_layer.geo_raster_layer.resource_name
			return feature_layer
	else:
		if is_raster:
			var raster_layer = RasterLayer.new()
			raster_layer.geo_raster_layer = Geodot.get_raster_layer(file_name.text)
			raster_layer.name = file_name.text.get_file() 
			return raster_layer
		else:
			var feature_layer = FeatureLayer.new()
			feature_layer.geo_feature_layer = Geodot.get_raster_layer(file_name.text)
			feature_layer.name = file_name.text.get_file() 
			return feature_layer
		
