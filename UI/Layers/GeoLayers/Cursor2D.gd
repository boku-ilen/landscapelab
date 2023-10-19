extends Sprite2D


@export var camera_2d: Camera2D


func _input(event):
	if event is InputEventMouseMotion:
		position = camera_2d.get_global_mouse_position() 
