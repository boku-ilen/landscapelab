extends ARVROrigin

func _process(delta):
	# Keep the VR player at the global player position
	translation = WorldPosition.get_position_on_ground(PlayerInfo.get_engine_player_position())
