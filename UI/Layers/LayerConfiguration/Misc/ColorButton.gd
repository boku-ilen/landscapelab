extends Button
tool


export var color: Color = Color.white setget set_color


func set_color(color: Color):
	get_node("MarginContainer/ColorRect").color = color
