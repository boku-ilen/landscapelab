extends RigidBody
class_name  InteractableObject

var controller: ARVRController


func _ready():
	add_to_group("Interactable")


func interact():
	pass


func picked_up(my_controller: ARVRController):
	controller =  my_controller


func dropped():
	if not controller == null:
		var position_before = controller.global_transform.origin
		yield(get_tree(), "physics_frame")
		yield(get_tree(), "physics_frame")
		var direction = controller.global_transform.origin - position_before
		apply_impulse(transform.origin, direction * 100)
		controller = null

