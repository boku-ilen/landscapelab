class_name GeodataChooser
extends VBoxContainer


export var show_raster_layers: bool = true
export var show_feature_layer: bool = true

# For geodot there is a differentiation between datasets and single files ...
var geo_dataset_extensions = [".shp", ".gpkg"]


signal new_layer_selected(layer)


func _ready():
	$FileChooser/Button/FileDialog.connect("file_selected", self, "_file_selected")
	$FileChooser/FileName.connect("text_changed", self, "_check_path")
	$OptionButton.connect("item_selected", self, "_on_item_selcted")


func _on_item_selcted(idx: int):
	if not show_raster_layers:
		var layer = get_geo_layer(false)
		emit_signal("new_layer_selected", layer)


func _check_path(which: String = ""):
	if is_current_file_dataset():
		_fill_dataset_options()


func _fill_dataset_options():
	var dataset = Geodot.get_dataset($FileChooser/FileName.text)
	if dataset.is_valid():
		_fill_options([], 0, true) # Empty all entries list
		var idx: int = 0
		if show_raster_layers:
			idx = _fill_options(dataset.get_raster_layers(), idx)
		if show_feature_layer:
			_fill_options(dataset.get_feature_layers(), idx)
		$OptionButton.visible = true
	else:
		_fill_options([], 0, true) # Empty all entries list
		$OptionButton.visible = false


func _file_selected(which: String):
	$FileChooser/FileName.text = which
	_check_path()


# As filling the $OptionButton with two different types of layers (feature and raster)
# the idx has to be assigned manually to fit the position in the list.
func _fill_options(which: Array, start_idx: int = 0, clear = false) -> int:
	if clear: $OptionButton.clear()
	for option in which:
		$OptionButton.add_item(option.resource_name)
	
	return start_idx


func is_current_file_dataset():
	return "." + $FileChooser/FileName.text.get_extension() in geo_dataset_extensions


func is_current_path_valid():
	var f = File.new()
	return f.file_exists($FileChooser/FileName.text)


func get_geo_layer(is_raster: bool = true):
	if not is_current_path_valid(): return null
	
	if is_current_file_dataset():
		var sub_layer_name = $OptionButton.get_item_text($OptionButton.get_selected_id())
		var dataset = Geodot.get_dataset($FileChooser/FileName.text)
		if is_raster:
			var raster_layer = RasterLayer.new()
			raster_layer.geo_raster_layer = dataset.get_raster_layer(sub_layer_name)
			raster_layer.name = raster_layer.geo_raster_layer.resource_name
			return raster_layer
		else:
			var feature_layer = FeatureLayer.new()
			feature_layer.geo_feature_layer = dataset.get_feature_layer(sub_layer_name)
			feature_layer.name = feature_layer.geo_feature_layer.resource_name
			return feature_layer
	else:
		if is_raster:
			var raster_layer = RasterLayer.new()
			raster_layer.geo_raster_layer = Geodot.get_raster_layer($FileChooser/FileName.text)
			raster_layer.name = $FileChooser/FileName.text.get_file() 
			return raster_layer
		else:
			var feature_layer = FeatureLayer.new()
			feature_layer.geo_feature_layer = Geodot.get_feature_layer($FileChooser/FileName.text)
			feature_layer.name = $FileChooser/FileName.text.get_file() 
			return feature_layer


func _get_dataset_option_by_name(_name: String):
	for i in range($OptionButton.get_item_count()):
		var curr_option_name = $OptionButton.get_item_text(i)
		if curr_option_name == _name:
			return i


func init_from_layer(layer: Layer):
	$FileChooser/FileName.text = layer.get_path()
	if is_current_file_dataset():
		_fill_dataset_options()
		var idx = _get_dataset_option_by_name(layer.get_name())
		if idx != null: $OptionButton.select(idx) 
