extends "res://addons/vr-extensions/ARVRControllerExtension.gd"

onready var area = get_node("Area")

var current_object = null


func _process(delta):
	if controller.is_button_pressed(2) and controller.is_button_pressed(15):
		if not area.get_overlapping_bodies() == null:
			for body in area.get_overlapping_bodies():
				if body.is_in_group("Interactable"):
					current_object = body
					break
	
	if current_object:
		current_object.global_transform.origin = global_transform.origin
