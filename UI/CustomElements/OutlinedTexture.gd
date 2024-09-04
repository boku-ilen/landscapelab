@tool
extends MarginContainer


@export var texture := Texture2D:
	set(new_texture):
		texture = new_texture
		$Outline.texture = new_texture
		$Texture.texture = new_texture

@export var outline_size := 5.0:
	set(new_outline_size):
		outline_size = new_outline_size
		$Outline.material.set_shader_parameter("border_width", outline_size)

@export var outline_color := Color(0.5, 0.8, 0.5):
	set(new_outline_color):
		outline_color = new_outline_color
		$Outline.material.set_shader_parameter("color", new_outline_color)
