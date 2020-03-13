tool
extends TextureButton


#
# Instead of using a separate texture for each state (default, pressed, ...),
# only colors have to be defined for this AutoTextureButton. The texture is
# then automatically colored accordingly.
# Also provides additional functionality for styling buttons such as rotating.
#

var icon_folder = "ColorOpenMoji" # TODO: Global setting

export(String) var texture_name setget set_texture_name, get_texture_name

export(Color) var default_color
export(Color) var pressed_color
export(Color) var hover_color
export(Color) var disabled_color
export(Color) var focused_color


func _enter_tree() -> void:
	_update_texture()


# Update the button's base texture
func _update_texture():
	var full_path = "res://Resources/Icons".plus_file(icon_folder).plus_file(texture_name) + ".svg"
	assert(File.new().file_exists(full_path), "No icon with name '%s' found in icon folder '%s'!" % [texture_name, icon_folder])
	
	texture_normal = load(full_path)


func set_texture_name(new_name: String):
	texture_name = new_name
	_update_texture()


func get_texture_name():
	return texture_name


# Rotate the sprite clockwise around its center by the given radians.
func set_rotation_radians(radians: float):
	material.set_shader_param("rotation_radians", radians)


# Rotate the sprite clockwise around its center by the given degrees.
func set_rotation_degrees(degrees: float):
	set_rotation_radians(deg2rad(degrees))


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
