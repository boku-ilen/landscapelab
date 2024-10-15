@tool
extends MarginContainer


@export var texture :Texture2D:
	set(new_texture):
		texture = new_texture
		$Texture.texture = new_texture
