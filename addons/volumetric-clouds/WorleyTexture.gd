extends Viewport


#
# Worley texture generator for ViewportTextures
# Adapted from Bastiaan Olij: https://github.com/BastiaanOlij/godot-worley-shader
# 


export var texture_size = Vector3(128.0, 128.0, 16.0) setget set_texture_size, get_texture_size
export var max_distance = 0.5 setget set_max_distance, get_max_distance

var color_rect = null
var material = null

# note, Godot doesn't currently have support for 3D textures, so we pack the Z into our Y
# slower because we need to do a double lookup but it'll do fine
# If you don't want a 3D texture, just keep Z to 1.0
func set_texture_size(new_size):
	if new_size.x < 1.0 or new_size.y < 1 or new_size.z < 1:
		return
	
	# remember
	texture_size = new_size
	
	# resize viewport
	size = Vector2(new_size.x, new_size.y * new_size.z);
	
	# resize our texture
	if color_rect:
		color_rect.rect_size = Vector2(new_size.x, new_size.y * new_size.z);
	
	# let our shader know...
	if material:
		material.set_shader_param("texture_rect", texture_size)
	
	# and re-render our viewport
	self.render_target_update_mode = Viewport.UPDATE_ONCE

func get_texture_size():
	return texture_size

func set_max_distance(p_distance):
	if p_distance < 0.01 or p_distance > 2.0:
		return
	
	max_distance = p_distance
	if material:
		material.set_shader_param("max_distance", max_distance)
	
	# and re-render our viewport
	self.render_target_update_mode = Viewport.UPDATE_ONCE

func get_max_distance():
	return max_distance

func _random():
	var point = Vector3(rand_range(0.0, 1.0), rand_range(0.0, 1.0), rand_range(0.0, 1.0))

func make_random_points():
	# should make a seed optional
	if material:
		material.set_shader_param("worley_point_01", _random())
		material.set_shader_param("worley_point_02", _random())
		material.set_shader_param("worley_point_03", _random())
		material.set_shader_param("worley_point_04", _random())
		material.set_shader_param("worley_point_05", _random())
		material.set_shader_param("worley_point_06", _random())
		material.set_shader_param("worley_point_07", _random())
		material.set_shader_param("worley_point_08", _random())
		material.set_shader_param("worley_point_09", _random())
		material.set_shader_param("worley_point_10", _random())
		material.set_shader_param("worley_point_11", _random())
		material.set_shader_param("worley_point_12", _random())
		material.set_shader_param("worley_point_13", _random())
		material.set_shader_param("worley_point_14", _random())
		material.set_shader_param("worley_point_15", _random())

func _ready():
	color_rect = get_node("ColorRect")
	material = color_rect.material
	
	# rerun these now that we're ready for em...
	set_texture_size(texture_size)
	set_max_distance(max_distance)
	
	# random generate some control point
	make_random_points()

