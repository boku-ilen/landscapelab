extends Spatial

func _process(delta):
	translation.y = WorldPosition.get_position_on_ground(global_transform.origin).y
