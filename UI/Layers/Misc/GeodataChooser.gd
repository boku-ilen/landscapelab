extends VBoxContainer


onready var file_dialog = get_node("FileChooser/Button/FileDialog")
onready var file_name = get_node("FileChooser/FileName")
onready var options = get_node("OptionButton")


func _ready():
	file_dialog.connect("file_selected", self, "_file_selected")
	file_name.connect("text_changed", self, "_check_path")


func _check_path():
	var file2Check = File.new()
	if file2Check.file_exists(file_name.text):
		# TODO: Geodot hocus pocus
		_fill_options(["Test", "TEST"])
		options.visible = true
	else:
		options.visible = false


func _file_selected(which: String):
	file_name.text = which
	_check_path()


func _fill_options(which: PoolStringArray):
	for option in which:
		options.add_item(option)
