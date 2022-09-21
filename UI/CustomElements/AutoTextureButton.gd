@tool
extends AutoIconButton


@export var default_color: Color
@export var pressed_color: Color
@export var hover_color: Color
@export var disabled_color: Color
@export var focused_color: Color


# Rotate the sprite clockwise around its center by the given radians.
func set_rotation_radians(radians: float):
	material.set_shader_parameter("rotation_radians", radians)


# Rotate the sprite clockwise around its center by the given degrees.
func set_rotation_degrees(degrees: float):
	set_rotation_radians(deg_to_rad(degrees))


# Overwritten default set_disabled function to also set the corresponding color
func set_disabled(new_disabled: bool):
	super.set_disabled(new_disabled)
	
	if new_disabled:
		_set_color(disabled_color)
	else:
		_set_color(default_color)


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered",Callable(self,"_mouse_entered"))
	connect("mouse_exited",Callable(self,"_mouse_exited"))
	connect("button_up",Callable(self,"_button_up"))
	connect("button_down",Callable(self,"_button_down"))
	
	if disabled:
		_set_color(disabled_color)
	else:
		_set_color(default_color)
	
	# If the button is toggled by default, set the color at the start
	if toggle_mode and button_pressed:
		_set_color(pressed_color)


func _set_color(color: Color):
	pass#material.set_shader_parameter("color", Vector3(color.r, color.g, color.b))


func _mouse_entered():
	if disabled:
		return
	
	if not button_pressed:
		_set_color(hover_color)


func _mouse_exited():
	if disabled:
		return
	
	if pressed:
		_set_color(pressed_color)
	else:
		_set_color(default_color)


func _button_up():
	if disabled:
		return
	
	if not toggle_mode or not button_pressed:
		_set_color(hover_color)


func _button_down():
	if disabled:
		return
	
	_set_color(pressed_color)
