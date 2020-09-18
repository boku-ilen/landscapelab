extends PopupMenu


onready var color_menu = get_node("ColorMenu")

signal change_color_tag(color)

var colors = {
	"None": Color(0, 0, 0, 0),
	"Green": Color.green,
	"Red": Color.red,
	"Blue": Color.blue,
	"Yellow": Color.yellow
}


func _ready():
	add_submenu_item("Color Tag", "ColorMenu")
	for key in colors.keys():
		color_menu.add_item(key)
	
	color_menu.connect("id_pressed", self, "_emit_color_change")


func _emit_color_change(id):
	emit_signal("change_color_tag", colors[color_menu.get_item_text(id)])
