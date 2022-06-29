extends Spatial

#
# This scene can be added to any node in order to display a tooltip for it when the player is nearby.
#

onready var label_node = get_node("Viewport/CenterContainer/PanelContainer/VBoxContainer/Label")
onready var icon_node = get_node("Viewport/CenterContainer/PanelContainer/VBoxContainer/MarginContainer/TextureRect")

export(String) var label setget set_label_text, get_label_text
export(Resource) var icon setget set_icon, get_icon

var ready = false


func _ready():
	visible = false
	#.connect("asset_show_tooltip", self, "_on_display_tooltip", [true])
	#GlobalSignal.connect("asset_hide_tooltip", self, "_on_display_tooltip", [false])
	ready = true
	update()


func update():
	if ready:
		if label != null:
			label_node.text = label
		icon_node.texture = icon


# Set the text to display on the tooltip
func set_label_text(text):
	label = text
	update()


func get_label_text():
	return label_node.text


# Set an icon to display above the text
func set_icon(img):
	icon = img
	update()


func get_icon():
	return icon_node.texture


func _on_display_tooltip(should_display):
	visible = should_display
