extends HBoxContainer


export var filters: PoolStringArray = ["*.shp", "*.gpkg"]

onready var button = get_node("Button")
onready var file_dialog = get_node("Button/FileDialog")
onready var file_name = get_node("FileName")


func _ready():
	file_dialog.filters = filters
	button.connect("pressed", self, "_pop_file_dialog")
	file_dialog.connect("file_selected", self, "_file_selected")


func _pop_file_dialog():
	file_dialog.popup(Rect2(button.rect_global_position, Vector2(500, 400)))


func _file_selected(which: String):
	file_name.set_text(which)



