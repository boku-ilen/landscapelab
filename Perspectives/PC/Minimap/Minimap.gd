extends Spatial

#
# Basic minimap implementation which uses an orthographic camera placed above the player.
#

onready var cam = get_node("Camera")

var CAMERA_HEIGHT = Settings.get_setting("minimap", "height")

func _process(delta):
	# Set position to the last known player location, but at a fixed height
	var player_pos = PlayerInfo.get_engine_player_position()
	cam.translation = player_pos
	cam.translation.y = CAMERA_HEIGHT
