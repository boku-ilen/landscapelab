extends ARVRCamera


func get_look_direction():
	return -global_transform.basis.z


func _physics_process(delta):
	PlayerInfo.update_player_look_direction(get_look_direction())