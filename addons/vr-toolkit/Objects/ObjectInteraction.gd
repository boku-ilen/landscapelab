extends "res://addons/vr-toolkit/ARVRControllerExtension.gd"

# https://docs.godotengine.org/en/latest/classes/class_@globalscope.html#enum-globalscope-joysticklist
export(int) var pick_up_id = 2
export(int) var interact_id = 15

onready var area = get_node("Area")

# The picked up object
var current_object: InteractableObject = null
# The initial transform of the object when picking up
var original_object_transform: Transform = Transform.IDENTITY


func _process(delta):
	# If we are currently holding an object we will translate it with the controller
	if current_object:
		current_object.global_transform.origin = global_transform.origin
		# Apply the rotation since the object has been picked up
		current_object.global_transform.basis = global_transform.basis * original_object_transform.basis
		# Prevent floating point inaccuracy 
		current_object.global_transform = current_object.global_transform.orthonormalized()


func on_button_released(id: int):
	# If we are no longer holding the object we will call for its dropped method 
	# and set the current_object to null
	if id == pick_up_id:
		if current_object:
			current_object.dropped()
			current_object = null


func on_button_pressed(id: int):
	# If the object we try to pick up is in the group of interactable, we will 
	# set our current_object to this object
	if id == pick_up_id:
		current_object = _try_pick_up_interactable()
		if not current_object == null:
			# Save the transform of the object when it was taken, we need this 
			# to accurately compute the transform with the rotation of the controller
			original_object_transform = current_object.global_transform
			# Reset the basis of global_transform to Identity so only the rotation
			# from the moment it has been picked up will be applied, not the rotation
			# that the controller already has when picking up
			global_transform.basis = Basis.IDENTITY
	# To prevent errors we will first check if the current object is set and then 
	# call for its interact method
	elif id == interact_id:
		if not current_object == null:
			current_object.interact()


func _try_pick_up_interactable():
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Interactable"):
			body.picked_up(controller)
			return body
