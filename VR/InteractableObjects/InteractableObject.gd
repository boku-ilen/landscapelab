extends Spatial
class_name  InteractableObject

var controller: ARVRController


func _ready():
	add_to_group("Interactable")


func interact():
	pass


func picked_up(my_controller: ARVRController):
	controller =  my_controller


func dropped():
	pass
