extends TextureButton


#
# Instead of using a separate texture for each state (default, pressed, ...),
# only colors have to be defined for this AutoTextureButton. The texture is
# then automatically colored accordingly.
#


export(Color) var default_color
export(Color) var pressed_color
export(Color) var hover_color
export(Color) var disabled_color
export(Color) var focused_color


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", self, "_mouse_entered")
	connect("mouse_exited", self, "_mouse_exited")
	connect("button_up", self, "_button_up")
	connect("button_down", self, "_button_down")
	
	if disabled:
		_set_color(disabled_color)
	
	# If the button is toggled by default, set the color at the start
	if toggle_mode and pressed:
		_set_color(pressed_color)


func _set_color(color: Color):
	material.set_shader_param("color", Vector3(color.r, color.g, color.b))


func _mouse_entered():
	if disabled:
		return
	
	if not pressed:
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
	
	if not toggle_mode or not pressed:
		_set_color(hover_color)


func _button_down():
	if disabled:
		return
	
	_set_color(pressed_color)
