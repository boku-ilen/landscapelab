extends Node3D


@onready var origin: Node3D = get_parent()
@onready var cursor: RayCast3D = get_parent().get_node("InteractRay")
@onready var thrown_objects = get_node("ThrownObjects")

@export var object_to_throw_scene: PackedScene


func _unhandled_input(event):
	if event.is_action_pressed("throw_physics_ball"):
		var direction = cursor.cast_to.normalized()
		var instance_position = origin.global_transform.origin
		
		var instance = object_to_throw_scene.instantiate() as RigidBody3D
		thrown_objects.add_child(instance)
		
		instance.global_transform.origin = instance_position + direction * 20.0
		instance.apply_central_impulse(direction * 10000.0)
