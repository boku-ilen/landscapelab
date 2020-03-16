extends "res://addons/vr-extensions/ARVRControllerExtension.gd"

export(float) var ray_length = 100
export(SpatialMaterial) var visualizer_material = SpatialMaterial.new()
export(float) var point_radius = 0.2

onready var interact_ray: RayCast = get_node("RayCast")
onready var line_visualizer = get_node("ImmediateGeometry")
onready var point_visualizer = get_node("Node/MeshInstance")


func _ready():
	line_visualizer.set_material_override(visualizer_material)
	point_visualizer.set_material_override(visualizer_material)
	interact_ray.set_cast_to(Vector3(0,0,-ray_length))
	
	var direction = -(controller.get_global_transform().basis.z) * ray_length
	draw_line(translation, direction)


func _process(delta):
	if interact_ray.is_colliding():
		point_visualizer.set_visible(true)
		point_visualizer.global_transform.origin = interact_ray.get_collision_point()
		if interact_ray.get_collider().get_parent().is_in_group("VRGui"):
			var from = global_transform.origin
			var to = interact_ray.get_collision_point()
			
			interact_ray.get_collider().get_parent().ray_interaction_input(from, to, InputEventMouseMotion)
	else:
		point_visualizer.set_visible(false)


func draw_line(var begin: Vector3, var end: Vector3):
	line_visualizer.clear()
	line_visualizer.begin(Mesh.PRIMITIVE_LINES)
	line_visualizer.add_vertex(begin)
	line_visualizer.add_vertex(end)
	line_visualizer.end()


func on_button_pressed(id: int):
	if id == 14:
		if interact_ray.get_collider().get_parent().is_in_group("VRGui"):
			var from = global_transform.origin
			var to = interact_ray.get_collision_point()
			interact_ray.get_collider().get_parent().ray_interaction_input(from, to, InputEventMouseButton, true)


func on_button_released(id: int):
	if id == 14:
		if interact_ray.get_collider().get_parent().is_in_group("VRGui"):
			var from = global_transform.origin
			var to = interact_ray.get_collision_point()
			interact_ray.get_collider().get_parent().ray_interaction_input(from, to, InputEventMouseButton, false)
