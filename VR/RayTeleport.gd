extends "res://addons/vr-extensions/ARVRControllerExtension.gd"


export var collision_mask = 1
export(float) var min_pitch = -80
export(float) var max_pitch = 90
export(float) var max_distance = 5000
export(float) var cast_height = 6
export(bool) var testing

onready var horizontal_ray = get_node("HorizontalRay")
# Remote transform does not work
onready var tall_ray = origin.get_node("TallRay")
onready var position_indicator = get_node("PositionIndicator")
onready var visualizer = get_node("ImmediateGeometry")

var horizontal_point: Vector3
var tall_ray_collision: Vector3


func _ready():
	testing = origin.testing
	tall_ray.enabled = true
	horizontal_ray.enabled = true


func _on_button_pressed(id):
	# 1 equals Y on rift
	if id == 1:
		if not tall_ray_collision == null:
			if not testing: 
				PlayerInfo.update_player_pos(tall_ray_collision)
			else:
				origin.get_parent().translation = tall_ray_collision


func _process(delta):
	_find_horizontal_point()
	_find_cast_position()
	
	tall_ray_collision = tall_ray.get_collision_point()
	position_indicator.global_transform.origin = tall_ray_collision
	
	_visualize()


# Finds the maximum distance along the horizontal ray
func _find_horizontal_point():
	# The controller pitch is somewhat messed up and not quite what you would expect.
	# This unexpected pitch is compensated by the raycast node itself, thus get the pitch from it. 
	var controller_pitch = rad2deg(horizontal_ray.global_transform.basis.get_euler().x) 
	controller_pitch = clamp(controller_pitch, min_pitch, max_pitch) # clamp the wished maximum rotations of the controller
	# Normalize the current pitch somewhere between 0 (min_pitch) and 1 (max_pitch)
	var normalized_pitch = inverse_lerp(min_pitch, max_pitch, controller_pitch)
	
	var horizontal_distance = max_distance * normalized_pitch
	# The resulting point is the horizontal_distance in pointing direction of the controller away from its origin
	horizontal_point = horizontal_ray.get_global_transform().origin + -horizontal_ray.get_global_transform().basis.z * horizontal_distance


func _find_cast_position():
	# The origin of the tall_ray is the arvr origin + a given height above
	var cast_position = origin.get_global_transform().origin + Vector3.UP * cast_height
	var cast_direction = horizontal_point - tall_ray.global_transform.origin
	
	tall_ray.global_transform.origin = cast_position
	tall_ray.cast_to = cast_direction


func _visualize():
	visualizer.clear()
	visualizer.begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var start_pos = controller.get_global_transform().origin
	# end_pos = tall_ray_collision
	var normal = (start_pos - tall_ray_collision).cross(Vector3.UP)
	var mid_vertex = (tall_ray_collision + controller.get_global_transform().origin) / 2 + normal
	
	visualizer.set_uv(Vector2(0, 1))
	visualizer.set_normal(Vector3(0, 0, 1))
	visualizer.add_vertex(start_pos)
	visualizer.set_uv(Vector2(1, 1))
	visualizer.set_normal(Vector3(0, 0, 1))
	visualizer.add_vertex(mid_vertex)
	visualizer.set_uv(Vector2(0, 0))
	visualizer.set_normal(Vector3(0, 0, 1))
	visualizer.add_vertex(tall_ray_collision)
