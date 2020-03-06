extends "res://addons/vr-extensions/ARVRControllerExtension.gd"

export(int) var pick_up_button_id = 2

onready var area = get_node("Area")

var current_object: InteractableObject = null


func _process(delta):
	# Side grip and front shoulder button
	if current_object:
		current_object.global_transform = global_transform


func on_button_released(id: int):
	if id == pick_up_button_id:
		if current_object:
			current_object.dropped()
			current_object = null


func on_button_pressed(id: int):
	if id == pick_up_button_id:
		current_object = _try_pick_up_interactable()


func _try_pick_up_interactable():
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Interactable"):
			body.picked_up(controller)
			return body
