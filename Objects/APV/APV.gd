@tool
extends Node3D


@export var apv_scene: PackedScene
@export var apv_rotation := -90.0

@export var extent_x := 100
@export var extent_z := 100

@export var distance_x := 10.0
@export var distance_z := 20.0

var center
var height_layer
var height_already_set = false


func _ready():
	for offset_x in range(-extent_x / 2.0, extent_x / 2.0, distance_x):
		for offset_z in range(-extent_z / 2.0, extent_z / 2.0, distance_z):
			var instance = apv_scene.instantiate()
			instance.rotation.y = deg_to_rad(apv_rotation)
			
			instance.position.x = offset_x
			instance.position.z = offset_z
			
			add_child(instance)


func set_height(origin):
	if height_already_set: return
	
	for child in get_children():
		var pos_x = center[0] + origin.x + child.position.x
		var pos_y = center[1] - origin.z - child.position.z
		var height_left = height_layer.get_value_at_position(pos_x - 4.0, pos_y)
		var height_right = height_layer.get_value_at_position(pos_x + 4.0, pos_y)
		
		var angle = Vector3(4.0, 0.0, 0.0).signed_angle_to(Vector3(8.0, height_right - height_left, 0.0), -Vector3.FORWARD)
		
		child.position.y = (height_left + height_right) / 2.0
		child.rotation.z = angle
	
	height_already_set = true
