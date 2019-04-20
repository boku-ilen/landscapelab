extends Spatial

# Basic minimap implementation which uses an orthographic camera placed above the player.

onready var cam = get_node("Camera")

func _process(delta):
	# Update position
	var player_pos = PlayerInfo.get_engine_player_position()
	cam.translation = player_pos + Vector3(0, 1000, 0)
