extends Camera3D

var rot_x = 0
var rot_y = 0

const LOOKAROUND_SPEED = 0.005

var is_right_mouse_button_down = false


func _input(event):
	if event is InputEventMouseMotion:
		if is_right_mouse_button_down == true:
			rot_x -= event.relative.x * LOOKAROUND_SPEED
			rot_y -= event.relative.y * LOOKAROUND_SPEED

			transform.basis = Basis()

			rotate_object_local(Vector3(0, 1, 0), rot_x)
			rotate_object_local(Vector3(1, 0, 0), rot_y)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_right_mouse_button_down = event.pressed

			if is_right_mouse_button_down:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
