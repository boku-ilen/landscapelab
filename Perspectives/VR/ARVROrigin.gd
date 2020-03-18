extends ARVROrigin


onready var camera = get_node("SettingsARVRCamera")

export(bool) var testing = false


func _process(delta):
	# Keep the VR player at the global player position
	if not testing and WorldPosition.has_handler():
		translation = WorldPosition.get_position_on_ground(PlayerInfo.get_engine_player_position())
	
	PlayerInfo.update_player_look_direction(-(camera.global_transform.basis.z))
