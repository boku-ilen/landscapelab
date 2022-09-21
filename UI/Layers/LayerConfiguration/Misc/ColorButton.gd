extends Button
@tool


@export var color: Color = Color.WHITE :
	get:
		return color # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_color


func set_color(new_color: Color):
	color = new_color
	get_node("MarginContainer/ColorRect").color = new_color
