extends HSplitContainer


onready var color_checkbox = get_node("RightBox/CheckBox")
onready var label_color_min = get_node("LeftBox/ColorMin")
onready var label_color_max = get_node("LeftBox/ColorMax")
onready var button_color_min = get_node("RightBox/ButtonMin")
onready var button_color_max = get_node("RightBox/ButtonMax")


func _ready():
	color_checkbox.connect("toggled", self, "_toggle_color_menu")
	button_color_min.connect("pressed", self, "_pop_color_picker", [button_color_min])
	button_color_max.connect("pressed", self, "_pop_color_picker", [button_color_max])


func _toggle_color_menu(toggled: bool):
	button_color_max.visible = toggled
	label_color_max.visible = toggled
	button_color_min.visible = toggled
	label_color_min.visible = toggled


func _pop_color_picker(button: Button):
	var color_dialog = button.get_node("ConfirmationDialog")
	var color_picker = color_dialog.get_node("ColorPicker")
	color_dialog.connect("confirmed", self, "_set_color", [button, color_picker])
	color_dialog.popup(Rect2(button.rect_global_position, Vector2(0,0)))


func _set_color(button: Button, color_picker: ColorPicker):
	button.color = color_picker.color
