extends ARVROrigin


onready var camera = get_node("SettingsARVRCamera")


func _process(delta):
	# Keep the VR player at the global player position
	translation = WorldPosition.get_position_on_ground(PlayerInfo.get_engine_player_position())
	
	PlayerInfo.update_player_look_direction(-(camera.global_transform.basis.z))
