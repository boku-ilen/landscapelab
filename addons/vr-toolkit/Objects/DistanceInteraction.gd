extends "res://addons/vr-toolkit/Controller/ControllerTool.gd"

export(float) var ray_length = 100
export(SpatialMaterial) var line_material = SpatialMaterial.new()
export(bool) var enabled = true

onready var interact_ray: RayCast = get_node("RayCast")
onready var line_visualizer = get_node("LineRenderer")
onready var tween = get_node("Tween")

var direction: Vector3
var hovered_object setget set_hovered_object



func set_hovered_object(object):
	if not object == hovered_object:
		if not hovered_object == null and not hovered_object.outline_mesh == null:
			hovered_object.outline_mesh.visible = false
		if not object == null and not object.outline_mesh == null:
			object.outline_mesh.set_surface_material(0, line_material)
			object.outline_mesh.visible = true
		
		hovered_object = object


func _ready():
	$Inputs/InteractInput.connect("pressed", self, "interact", [true])
	$Inputs/InteractInput.connect("released", self, "interact", [false])
	
	line_visualizer.set_material_override(line_material)
	
	interact_ray.set_cast_to(-(transform.basis.z) * ray_length)
	
	direction = -(transform.basis.z) * ray_length
	line_visualizer.set_points([Vector3.ZERO, direction])


func _process(delta):
	# Logic + visualization is only active if enabled
	if enabled:
		show()
		if interact_ray.is_colliding():
			
			# The line should end where the ray collides - thus we find the 
			# distance from the start point colliding point and with it we multiply forward
			var colliding_distance = global_transform.origin.distance_to(interact_ray.get_collision_point())
			line_visualizer.set_points([Vector3.ZERO, direction.normalized() * colliding_distance])
			
			# save the hovered object
			set_hovered_object(interact_ray.get_collider())
		else:
			# Not colliding -> longer ray and no hovered_object
			set_hovered_object(null)
			line_visualizer.set_points([Vector3.ZERO, direction])
	else:
		hide()


func interact(pressed: bool):
	# Only make interaction possible if enabled
	if enabled:
		if pressed:
			if not interact_ray.get_collider() == null:
				var object_transform = hovered_object.global_transform
				tween.interpolate_property(hovered_object, "global_transform:origin",
					object_transform.origin, global_transform.origin, 1,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
				tween.start()
