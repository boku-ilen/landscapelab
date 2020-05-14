extends GroundedSpatial

func _place_on_ground():
	._place_on_ground()
	
	var normal_on_ground = WorldPosition.get_normal_on_ground(global_transform.origin)
	normal_on_ground.z = 0
	
	var angle = normal_on_ground.angle_to(Vector3.UP)
	if normal_on_ground.x > 0:
		angle = -angle
	
	rotation.z = angle
