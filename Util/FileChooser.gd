extends HBoxContainer


@export var text_placeholder := "..." :
	get:
		return text_placeholder # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_text_placeholder
@export var filters: PackedStringArray = ["*.shp", "*.gpkg", "*.tif"]
@export var current_dir: String = "res://" :
	get:
		return current_dir # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_dir

@onready var button = get_node("Button")
@onready var file_dialog = get_node("Button/FileDialog") 
@onready var file_name = get_node("FileName")


func _ready():
	file_dialog.filters = filters
	button.connect("pressed",Callable(self,"_pop_file_dialog"))
	file_dialog.connect("file_selected",Callable(self,"_file_selected"))
	
	set_text_placeholder(text_placeholder)


func _pop_file_dialog():
	file_dialog.popup(Rect2(button.global_position, Vector2(500, 400)))


func _file_selected(which: String):
	file_name.set_text(which)


func set_dir(dir: String):
	if dir:
		$Button/FileDialog.set_current_dir(dir)


func set_text_placeholder(text: String):
	text_placeholder = text
	
	if $FileName:
		$FileName.placeholder_text = text
