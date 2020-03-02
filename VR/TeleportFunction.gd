extends "res://addons/vr-extensions/ARVRControllerExtension.gd"


export var collision_mask = 1
export(Color) var can_teleport_color = Color(0,1,1)
export(Color) var cannot_teleport_color = Color(1,0,0)
export(Color) var no_collision_color = Color(0,1,0)
export(float) var min_pitch = -80
export(float) var max_pitch = 90
export(float) var max_distance = 5000
export(float) var cast_height = 6

onready var horizontal_ray = get_node("HorizontalRay")
onready var tall_ray = origin.get_node("TallRay")

var horizontal_point: Vector3


func _on_button_pressed(id):
	# 1 equals Y on rift
	if id == 1:
		var collision_point = tall_ray.get_collision_point()
		if not collision_point == null:
			origin.get_parent().translation = collision_point


func _on_button_released(id):
	print("Released button with id %d" [id])
	if id == 1:
		horizontal_ray.enabled = false
		tall_ray.enabled = false


func _physics_process(delta):
	horizontal_point = _find_horizontal_point()
	_find_cast_position()


func _find_horizontal_point():
	var controller_pitch = rad2deg(horizontal_ray.global_transform.basis.get_euler().x)
	controller_pitch = clamp(controller_pitch, min_pitch, max_pitch)
	var normalized_pitch = inverse_lerp(min_pitch, max_pitch, controller_pitch)
	print(normalized_pitch)
	
	var horizontal_distance = max_distance * normalized_pitch
	var point = horizontal_ray.transform.origin + -horizontal_ray.get_global_transform().basis.z * horizontal_distance
	
	return point


func _find_cast_position():
	var cast_position = origin.translation + Vector3.UP * cast_height
	var cast_direction = horizontal_point - cast_position
	
	tall_ray.translation = cast_position
	tall_ray.cast_to = cast_direction


func _draw_bezier():
	pass
