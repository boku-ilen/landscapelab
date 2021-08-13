extends Node
tool


#
# Attach this Node as a child to any spatial you want to always be fixed on 
# the ground (no matter of level of detail, etc ...)
#


export var is_active := true setget set_active
# Distance above ground any time
export var above_height := 5


func set_active(active: bool) -> void:
	is_active = active
	$RayCast.enabled = active


func _process(delta):
	if $RayCast.is_colliding() and "translation" in get_parent():
		# Apply parent x, z to the raycast
		var parent_pos = get_parent().global_transform.origin
		$RayCast.translation = Vector3(parent_pos.x, $RayCast.translation.y, parent_pos.z)
		# Apply raycast collision-height to parent
		get_parent().translation.y = $RayCast.get_collision_point().y
