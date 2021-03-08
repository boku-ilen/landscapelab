extends HBoxContainer


var current_color: Color

var auto_button = preload("res://UI/Layers/LayerConfiguration/Misc/ColorButton.tscn")

onready var color_indicator = get_node("ColorRect")

var colors = {
	"None": Color(0, 0, 0, 0),
	"Green": Color.green,
	"Red": Color.red,
	"Blue": Color.blue,
	"Yellow": Color.yellow
}


func _ready():
	for color in colors:
		var color_button = auto_button.instance()
		color_button.get_node("MarginContainer/ColorRect").color = colors[color]
		add_child(color_button)
		color_button.connect("pressed", self, "_color_change", [colors[color]])


func _color_change(c: Color):
	color_indicator.color = c
	current_color = c
