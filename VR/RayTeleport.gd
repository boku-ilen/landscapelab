extends "res://addons/vr-extensions/ARVRControllerExtension.gd"


export var collision_mask = 1
export(float) var min_pitch = -80
export(float) var max_pitch = 90
export(float) var max_distance = 5000
export(float) var cast_height = 6
export(bool) var testing
export(Color) var can_teleport = Color.green
export(Color) var cannot_teleport = Color.red

onready var horizontal_ray = get_node("HorizontalRay")
# Remote transform does not work, thus we make a node to undock it from the controller.
# Then we set the position each frame.
onready var tall_ray = get_node("Node/TallRay")
onready var position_indicator = get_node("PositionIndicator")
onready var visualizer = get_node("Node/Visualizer")
onready var bezier = Curve3D.new()

var horizontal_point: Vector3
export(SpatialMaterial) var visualizer_material = SpatialMaterial.new()


func _ready():
	testing = origin.testing
	tall_ray.enabled = true
	horizontal_ray.enabled = true
	visualizer.set_material_override(visualizer_material)
	position_indicator.set_material_override(visualizer_material)
	_init_bezier()


# Because we need to have 3 points to draw the bezier we have to initialize them
# with a value
func _init_bezier():
	bezier.add_point(Vector3.ZERO)
	bezier.add_point(Vector3.ZERO)
	bezier.add_point(Vector3.ZERO)


func _on_button_pressed(id):
	# 1 equals Y on rift
	if id == 1:
		if tall_ray.is_colliding():
			if not testing: 
				PlayerInfo.update_player_pos(tall_ray.get_collision_point())
			else:
				origin.get_parent().translation = tall_ray.get_collision_point()


func _process(delta):
	tall_ray.global_transform.origin = origin.global_transform.origin + Vector3.UP * cast_height
	_find_horizontal_point()
	_find_cast_position()
	
	if tall_ray.is_colliding():
		position_indicator.visible = true
		position_indicator.global_transform.origin = tall_ray.get_collision_point()
		visualizer_material.albedo_color = can_teleport
		visualizer_material.emission = can_teleport
	else:
		position_indicator.visible = false
		visualizer_material.albedo_color = cannot_teleport
		visualizer_material.emission = cannot_teleport
	
	_draw_bezier()
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


func _draw_bezier():
	var start_pos = controller.get_global_transform().origin
	var end_pos
	if tall_ray.is_colliding():
		end_pos = tall_ray.get_collision_point()
	else:
		end_pos = tall_ray.to_global(tall_ray.cast_to)
	
	var mid_pos = (end_pos + start_pos) / 2 + Vector3.UP * cast_height
	
	bezier.set_point_position(0, start_pos)
	bezier.set_point_position(1, mid_pos)
	bezier.set_point_position(2, end_pos)
	# Also set the in- and out-point (this makes the bezier effect)
	var direction = (end_pos - start_pos).normalized()
	bezier.set_point_in(1, direction * -2)
	bezier.set_point_out(1, direction * 2)


func _visualize():
	visualizer.clear()
	visualizer.begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for vertex in bezier.get_baked_points():
		visualizer.add_vertex(vertex)
	
	visualizer.end()
