extends RayCast


var position_on_ground: Vector3

onready var parent = get_parent()


func _process(delta):
	if not get_collider() == null:
		var height = get_collider().get_parent().get_height_at_position(get_collision_point())
		
		parent.transform.origin = Vector3(parent.transform.origin.x, height, parent.transform.origin.z)
