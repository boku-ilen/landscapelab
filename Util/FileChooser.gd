extends HBoxContainer


@export var text_placeholder := "..." :
	get:
		return text_placeholder
	set(text):
		text_placeholder = text
		
		if has_node("FileName"):
			get_node("FileName").placeholder_text = text

@export var filters: PackedStringArray = ["*.shp", "*.gpkg", "*.tif"]

@export var current_dir: String = "res://"

@onready var button = get_node("Button")
@onready var file_dialog = get_node("Button/FileDialog") 
@onready var file_name = get_node("FileName")

signal file_selected


func _ready():
	file_dialog.filters = filters
	
	if current_dir:
		$Button/FileDialog.set_current_dir(current_dir)
	
	button.pressed.connect(_pop_file_dialog)
	file_dialog.file_selected.connect(_file_selected)


func _pop_file_dialog():
	file_dialog.popup(Rect2(button.global_position, Vector2(500, 400)))


func _file_selected(path: String):
	file_name.set_text(path)
	file_selected.emit(path)
