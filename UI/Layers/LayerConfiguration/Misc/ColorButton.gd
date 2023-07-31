@tool
extends Button


@export var color := Color.WHITE :
	get:
		return color
	set(new_color):
		color = new_color
		get_node("MarginContainer/ColorRect").color = new_color
