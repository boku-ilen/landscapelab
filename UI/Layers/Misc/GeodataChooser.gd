extends VBoxContainer


export var show_raster_layers: bool = true
export var show_feature_layer: bool = true

onready var file_dialog = get_node("FileChooser/Button/FileDialog")
onready var file_name = get_node("FileChooser/FileName")
onready var options = get_node("OptionButton")


func _ready():
	file_dialog.connect("file_selected", self, "_file_selected")
	file_name.connect("text_changed", self, "_check_path")


func _check_path():
	var geopackage = Geodot.get_dataset(file_name.text)
	if geopackage.is_valid():
		var idx: int
		if show_raster_layers:
			idx = _fill_options(geopackage.get_raster_layers())
		if show_feature_layer:
			_fill_options(geopackage.get_feature_layers(), idx)
		options.visible = true
	else:
		options.visible = false


func _file_selected(which: String):
	file_name.text = which
	_check_path()


# As filling the options with two different types of layers (feature and raster)
# the idx has to be assigned manually to fit the position in the list.
func _fill_options(which: Array, start_idx: int = 0) -> int:
	for option in which:
		options.add_item(option.resource_name)
		options.set_item_metadata(start_idx, option)
		start_idx += 1
	
	return start_idx
