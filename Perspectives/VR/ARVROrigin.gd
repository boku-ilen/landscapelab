extends ARVROrigin

func _process(delta):
	# Keep the VR player at the global player position
	translation = Vector3(PlayerInfo.get_engine_player_position().x, 0, PlayerInfo.get_engine_player_position().z)