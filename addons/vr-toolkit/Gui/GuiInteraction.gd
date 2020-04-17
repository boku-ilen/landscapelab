extends "res://addons/vr-toolkit/Controller/ControllerTool.gd"

export(float) var ray_length = 100
export(SpatialMaterial) var line_material = SpatialMaterial.new()
export(SpatialMaterial) var indicator_material = SpatialMaterial.new()
export(float) var point_radius = 0.04
export(bool) var enabled = true

onready var interact_ray: RayCast = get_node("RayCast")
onready var line_visualizer = get_node("LineRenderer")
onready var point_visualizer = get_node("Node/MeshInstance")

var direction: Vector3

func _ready():
	$Inputs/MenuInput.connect("pressed", self, "toggle_menu", [true])
	$Inputs/MenuInput.connect("released", self, "toggle_menu", [false])
	$Inputs/InteractInput.connect("pressed", self, "interact", [true])
	$Inputs/InteractInput.connect("released", self, "interact", [false])
	
	line_visualizer.set_material_override(line_material)
	
	point_visualizer.set_material_override(indicator_material)
	point_visualizer.mesh.size = Vector2(point_radius, point_radius)
	
	interact_ray.set_cast_to(-(transform.basis.z) * ray_length)
	
	direction = -(transform.basis.z) * ray_length
	line_visualizer.set_points([Vector3.ZERO, direction])


func _process(delta):
	# Logic + visualization is only active if enabled
	if enabled:
		show()
		if interact_ray.is_colliding():
			# The point should not be visible if anything other than a UI-Element is hit, thus
			# I made the ray so it only collides with the specific collision mask of VRGui
			point_visualizer.set_visible(true)
			
			var collision_plane = Plane(interact_ray.get_collision_normal(), 0)
			var new_up = interact_ray.get_collision_normal()
			var new_forward = collision_plane.project(interact_ray.get_collision_point() - global_transform.origin).normalized()
			var new_right = new_forward.cross(new_up)
			point_visualizer.global_transform = Transform(new_right, new_up, -new_forward, interact_ray.get_collision_point())
			
			# The line should end where the ray collides - thus we find the 
			# distance from the start point colliding point and with it we multiply forward
			var colliding_distance = global_transform.origin.distance_to(interact_ray.get_collision_point())
			line_visualizer.set_points([Vector3.ZERO, direction.normalized() * colliding_distance])
			# Call the function which managed the input on the viewport in ViewportToMesh.gd
			interact_ray.get_collider().get_parent().ray_interaction_input(
			interact_ray.get_collision_point(), InputEventMouseMotion, controller_id)
		else:
			# Not colliding -> no point and longer ray
			point_visualizer.set_visible(false)
			line_visualizer.set_points([Vector3.ZERO, direction])
	else:
		hide()


func toggle_menu(pressed: bool):
	if pressed:
		_toggle_objects()


func interact(pressed: bool):
	# Only make interaction possible if enabled
	if enabled:
		if pressed:
			if not interact_ray.get_collider() == null:
					# Call the function which managed the input on the viewport in ViewportToMesh.gd
					interact_ray.get_collider().get_parent().ray_interaction_input(
						interact_ray.get_collision_point(), InputEventMouseButton, controller_id, true)
		else:
			if not interact_ray.get_collider() == null:
				# Call the function which managed the input on the viewport in ViewportToMesh.gd
				interact_ray.get_collider().get_parent().ray_interaction_input(
					interact_ray.get_collision_point(), InputEventMouseButton,  controller_id, false)


func _toggle_menu():
	var offset = Vector3.ZERO
	for menu in GlobalVRAccess.vr_menus:
		if not menu.visible:
			menu.visible = true
			menu.get_node("Area/CollisionShape").disabled = false
			menu.global_transform.origin = origin.global_transform.origin + -(origin.global_transform.basis.z) + offset
			offset += offset + Vector3.RIGHT
		else:
			# Set the visibility to false and disable the collision-shape so the
			# ray does not interact with an invisble object
			menu.visible = false
			menu.get_node("Area/CollisionShape").disabled = true


func _toggle_objects():
	if not GlobalVRAccess.object_menu.visible:
		GlobalVRAccess.object_menu.visible = true
		GlobalVRAccess.object_menu.global_transform.origin = origin.global_transform.origin + -(origin.global_transform.basis.z)
	
	GlobalVRAccess.object_menu.position_objects()
