extends "res://addons/vr-toolkit/Controller/ControllerTool.gd"

# https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#enum-globalscope-joysticklist
export(float) var min_pitch = -80
export(float) var max_pitch = 130
export(float) var max_distance = 500
export(float) var cast_height = 6
export(int) var curve_edges = 30
export(Color) var can_teleport = Color.green
export(Color) var cannot_teleport = Color.red
export(SpatialMaterial) var line_material = SpatialMaterial.new()
export(SpatialMaterial) var indicator_material = SpatialMaterial.new()

onready var horizontal_ray = get_node("HorizontalRay")
# Remote transform does not work, thus we make a node to undock it from the controller.
# Then we set the position each frame.
onready var tall_ray = get_node("Node/TallRay")
onready var position_indicator = get_node("PositionIndicator")
onready var visualizer = get_node("Node/LineRenderer")
onready var input = get_node("Inputs/TeleportInput")
onready var bezier = Curve3D.new()

var horizontal_point: Vector3
# In the LL the ARVRorigin is not the actual player
var player_node: KinematicBody


func set_origin(orig: ARVROrigin):
	if orig:
		.set_origin(orig)
		player_node = orig.get_parent()


func _ready():
	tall_ray.enabled = true
	horizontal_ray.enabled = true
	input.connect("released", self, "on_teleport")
	
	visualizer.set_material_override(line_material)
	position_indicator.set_material_override(indicator_material)
	_init_bezier()


func on_teleport():
	if tall_ray.is_colliding():
		if player_node:
			player_node.translation = tall_ray.get_collision_point()
		else:
			origin.translation = tall_ray.get_collision_point()


func _process(delta):
	if input.is_pressed():
		visualizer.show()
		show()
		tall_ray.global_transform.origin = origin.global_transform.origin + Vector3.UP * cast_height
		_find_horizontal_point()
		_find_cast_position()
	
		if tall_ray.is_colliding():
			position_indicator.visible = true
			
			var collision_plane = Plane(tall_ray.get_collision_normal(), 0)
			var new_up = tall_ray.get_collision_normal()
			var new_forward = collision_plane.project(tall_ray.get_collision_point() - global_transform.origin).normalized()
			var new_right = new_forward.cross(new_up)
			position_indicator.global_transform = Transform(new_right, new_up, -new_forward, tall_ray.get_collision_point())
			
			indicator_material.albedo_color = can_teleport
			line_material.albedo_color = can_teleport
			indicator_material.emission = can_teleport
			line_material.emission = can_teleport
		else:
			position_indicator.visible = false
			indicator_material.albedo_color = cannot_teleport
			line_material.albedo_color = cannot_teleport
			indicator_material.emission = cannot_teleport
			line_material.emission = cannot_teleport
	
		_draw_bezier()
		visualizer.points = bezier.get_baked_points()
	else:
		visualizer.hide()
		hide()


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
	var start_pos = get_global_transform().origin
	var end_pos
	var mid_pos
	
	if tall_ray.is_colliding():
		end_pos = tall_ray.get_collision_point()
	else:
		# In order to get a better feeling of where to navigate the bezier curve
		# when not colliding, the end point will be translated to a position downwards
		# the world coordinates of the actual casting direction of the ray.
		# This is multiplied by the max_distance so it is dynamic.
		end_pos = tall_ray.to_global(tall_ray.cast_to) + Vector3.DOWN * max_distance / 100
	
	var distance = start_pos.distance_to(end_pos)
	# The mid point will get higher, the further away the collision happens
	mid_pos = (end_pos + start_pos) / 2 + Vector3.UP * (distance / 5)
	
	bezier.set_point_position(0, start_pos)
	bezier.set_point_position(1, mid_pos)
	bezier.set_point_position(2, end_pos)
	# Also set the in- and out-point (this makes the bezier effect)
	var direction = (end_pos - start_pos).normalized()
	bezier.set_point_in(1, direction * -0.2 * distance)
	bezier.set_point_out(1, direction * 0.2 * distance)
	
	bezier.set_bake_interval(distance / curve_edges)


# Because we need to have 3 points to draw the bezier we have to initialize them
# with a value
func _init_bezier():
	bezier.add_point(Vector3.ZERO)
	bezier.add_point(Vector3.ZERO)
	bezier.add_point(Vector3.ZERO)
