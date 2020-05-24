extends Spatial

#
# Attach this scene to the MousePoint scene. It will give an indicator on where the
# mouse cursor in the world is currently placed. 
#


onready var cursor: RayCast = get_parent().get_node("InteractRay")

func _process(delta):
	if cursor.is_colliding():
		global_transform.origin = WorldPosition.get_position_on_ground(cursor.get_collision_point())
