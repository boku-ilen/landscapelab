extends "res://addons/vr-toolkit/ARVRControllerExtension.gd"

# https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#enum-globalscope-joysticklist
export(int) var teleport_id = 1
export(float) var min_pitch = -80
export(float) var max_pitch = 130
export(float) var max_distance = 500
export(float) var cast_height = 6
export(float) var controller_degree_compensation = -60
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
	tall_ray.enabled = true
	horizontal_ray.enabled = true
	visualizer.set_material_override(visualizer_material)
	position_indicator.set_material_override(visualizer_material)
	_init_bezier()
	horizontal_ray.rotation_degrees.x = controller_degree_compensation


# Because we need to have 3 points to draw the bezier we have to initialize them
# with a value
func _init_bezier():
	bezier.add_point(Vector3.ZERO)
	bezier.add_point(Vector3.ZERO)
	bezier.add_point(Vector3.ZERO)


func on_button_pressed(id):
	if id == teleport_id:
		if tall_ray.is_colliding():
			origin.translation = tall_ray.get_collision_point()


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
	
	# On very high pitches the cast_height has to scale up aswell, otherwise the 
	# tall_ray's cast_to will almost never collide with anything
#	var pitch = horizontal_ray.global_transform.basis.get_euler().x
#	if pitch < 0.8:
#		cast_position += Vector3.UP * pitch * 50

	tall_ray.global_transform.origin = cast_position
	tall_ray.cast_to = cast_direction


func _draw_bezier():
	var start_pos = controller.get_global_transform().origin
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
	mid_pos = (end_pos + start_pos) / 2 + Vector3.UP * (distance / 10)

	bezier.set_point_position(0, start_pos)
	bezier.set_point_position(1, mid_pos)
	bezier.set_point_position(2, end_pos)
	# Also set the in- and out-point (this makes the bezier effect)
	var direction = (end_pos - start_pos).normalized()
	bezier.set_point_in(1, direction * -2)
	bezier.set_point_out(1, direction * 2)


# Give the points of the curve to the ImmediateGeometry-Node which do the visualization
func _visualize():
	visualizer.clear()
	visualizer.begin(Mesh.PRIMITIVE_LINE_STRIP)

	for vertex in bezier.get_baked_points():
		visualizer.add_vertex(vertex)

	visualizer.end()
