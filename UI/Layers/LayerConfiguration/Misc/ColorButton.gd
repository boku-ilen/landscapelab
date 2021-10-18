extends Button
tool


export var color: Color = Color.white setget set_color


func set_color(new_color: Color):
	color = new_color
	get_node("MarginContainer/ColorRect").color = new_color
