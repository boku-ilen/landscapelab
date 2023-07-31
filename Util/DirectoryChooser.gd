extends HBoxContainer


@export var current_dir: String = "res://"

@onready var button = get_node("Button")
@onready var dir_dialog = get_node("Button/DirDialog")
@onready var dir_name = get_node("DirName")


func _ready():
	dir_dialog.current_dir = current_dir
	dir_dialog.current_path = current_dir
	button.connect("pressed",Callable(self,"_pop_file_dialog"))
	dir_dialog.connect("dir_selected",Callable(self,"_dir_selected"))


func _pop_file_dialog():
	dir_dialog.popup(Rect2(button.global_position, Vector2(500, 400)))


func _dir_selected(which: String):
	dir_name.set_text(which)
