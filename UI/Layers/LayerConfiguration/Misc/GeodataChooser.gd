class_name GeodataChooser
extends VBoxContainer


@export var text_placeholder: String = "..." : 
	set(new_text):
		text_placeholder = new_text
		if has_node("FileChooser/FileName"):
			get_node("FileChooser/FileName").placeholder_text = new_text

@export var show_raster_layers: bool = true
@export var show_feature_layer: bool = true

@export var show_write_access: bool = true :
	set(new_show): 
		show_write_access = new_show
		$WriteAccess.visible = show_write_access

# For geodot there is a differentiation between datasets and single files ...
var geo_dataset_extensions = [".shp", ".gpkg"]


signal new_layer_selected(layer)


func _ready():
	$FileChooser/Button/FileDialog.connect("file_selected",Callable(self,"_file_selected"))
	$FileChooser/FileName.connect("text_changed",Callable(self,"_check_path"))
	$OptionButton.connect("item_selected",Callable(self,"_on_item_selcted"))


func _on_item_selcted(idx: int):
	if not show_raster_layers:
		new_layer_selected.emit(_get_geo_layer())


func _check_path(_which: String = ""):
	if is_current_file_dataset():
		_fill_dataset_options()
		new_layer_selected.emit(_get_geo_layer())


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
		$OptionButton.add_item(option.get_file_info()["name"])
	
	return start_idx


func is_current_file_dataset():
	return "." + $FileChooser/FileName.text.get_extension() in geo_dataset_extensions


func is_current_path_valid():
	return FileAccess.file_exists($FileChooser/FileName.text)


func get_full_dataset_string():
	var access_str = $OptionButton.get_item_text($OptionButton.get_selected_id())
	var dataset_str = $FileChooser/FileName.text
	var access_mode = "w" if $WriteAccess/CheckBox.pressed else "r"
	return "{}:{}?{}".format([dataset_str, access_str, access_mode], "{}")


func _get_geo_layer():
	var dataset
	var access_str: String
	
	# Check whether the file is a dataset or needs to be loaded directly via Geodot
	if is_current_file_dataset():
		access_str = $OptionButton.get_item_text($OptionButton.get_selected_id())
		dataset = Geodot.get_dataset($FileChooser/FileName.text)
	else:
		access_str = $FileChooser/FileName.text
		dataset = Geodot
	
	# Get the raster/feature layer
	var geo_layer
	if dataset.has_method("get_feature_layer"):
		geo_layer = dataset.get_feature_layer(access_str)
	
	if geo_layer == null:
		geo_layer = dataset.get_raster_layer(access_str)
	
	return geo_layer


func _get_dataset_option_by_name(_name: String):
	for i in range($OptionButton.get_item_count()):
		var curr_option_name = $OptionButton.get_item_text(i)
		if curr_option_name == _name:
			return i


func init_from_layer(geolayer):
	var path = geolayer.get_dataset().get_file_info()["path"] \
			if geolayer is GeoFeatureLayer else geolayer.get_dataset().get_file_info()["path"]
	
	$FileChooser/FileName.text = path
	
	if is_current_file_dataset():
		_fill_dataset_options()
		var idx = _get_dataset_option_by_name(geolayer.get_name())
		if idx != null: $OptionButton.select(idx) 
