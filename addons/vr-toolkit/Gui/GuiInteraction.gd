extends "res://addons/vr-toolkit/ARVRControllerExtension.gd"

# https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#enum-globalscope-joysticklist
export(int) var interact_id = 15
export(int) var menu_id = 7
export(float) var ray_length = 100
export(SpatialMaterial) var visualizer_material = SpatialMaterial.new()
export(float) var point_radius = 0.04
export(bool) var enabled = true

onready var interact_ray: RayCast = get_node("RayCast")
onready var line_visualizer = get_node("ImmediateGeometry")
onready var point_visualizer = get_node("Node/MeshInstance")

var direction: Vector3

func _ready():
	line_visualizer.set_material_override(visualizer_material)
	
	point_visualizer.set_material_override(visualizer_material)
	point_visualizer.mesh.radius = point_radius
	point_visualizer.mesh.height = point_radius * 2
	
	interact_ray.set_cast_to(Vector3(0,0,-ray_length))
	
	direction = -(controller.get_global_transform().basis.z) * ray_length
	draw_line(translation, direction)


func _process(delta):
	# Logic + visualization is only active if enabled
	if enabled:
		show()
		if interact_ray.is_colliding():
			# The point should not be visible if anything other than a UI-Element is hit, thus
			# I made the ray so it only collides with the specific collision mask of VRGui
			point_visualizer.set_visible(true)
			point_visualizer.global_transform.origin = interact_ray.get_collision_point()
			
			# The line should end where the ray collides - thus we find the 
			# distance from the start point colliding point and with it we multiply forward
			var colliding_distance = global_transform.origin.distance_to(interact_ray.get_collision_point())
			draw_line(translation, direction.normalized() * colliding_distance)
			# Call the function which managed the input on the viewport in ViewportToMesh.gd
			interact_ray.get_collider().get_parent().ray_interaction_input(
				interact_ray.get_collision_point(), InputEventMouseMotion, controller.controller_id)
		else:
			# Not colliding -> no point and longer ray
			point_visualizer.set_visible(false)
			draw_line(translation, direction)
	else:
		hide()


func draw_line(var begin: Vector3, var end: Vector3):
	line_visualizer.clear()
	line_visualizer.begin(Mesh.PRIMITIVE_LINES)
	line_visualizer.add_vertex(begin)
	line_visualizer.add_vertex(end)
	line_visualizer.end()


func on_button_pressed(id: int):
	if id == menu_id:
		toggle_menu()
	elif enabled:
		if id == interact_id:
			if not interact_ray.get_collider() == null:
				# Call the function which managed the input on the viewport in ViewportToMesh.gd
				interact_ray.get_collider().get_parent().ray_interaction_input(
					interact_ray.get_collision_point(), InputEventMouseButton, controller.controller_id, true)


func on_button_released(id: int):
	if enabled:
		if id == interact_id:
			if not interact_ray.get_collider() == null:
				# Call the function which managed the input on the viewport in ViewportToMesh.gd
				interact_ray.get_collider().get_parent().ray_interaction_input(
					interact_ray.get_collision_point(), InputEventMouseButton, controller.controller_id, false)


func toggle_menu():
	var offset = Vector3.ZERO
	for menu in GlobalVRAccess.vr_menus:
		if not menu.visible:
			menu.visible = true
			menu.get_node("Area/CollisionShape").disabled = false
			menu.global_transform.origin = camera.global_transform.origin + -(camera.global_transform.basis.z) + offset
			offset += offset + Vector3.RIGHT
		else:
			# Set the visibility to false and disable the collision-shape so the
			# ray does not interact with an invisble object
			menu.visible = false
			menu.get_node("Area/CollisionShape").disabled = true
