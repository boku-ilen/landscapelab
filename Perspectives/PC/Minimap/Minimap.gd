extends Spatial

#
# Basic minimap implementation which uses an orthographic camera placed above the player.
#

onready var cam = get_node("Camera")

var CAMERA_HEIGHT = Settings.get_setting("minimap", "height")
var CAMERA_SIZE = Settings.get_setting("minimap", "size")


func _ready():
	change_size(CAMERA_SIZE)
	
	
# Changes the size of the minimap camera to the given 'size'.
# Size refers to the width/height of the camera making the orthographic projection.
# e.g. a size of 2000 results in a visible area of roughly 4000x3000.
func change_size(size):
	cam.size = size


func _process(delta):
	# Set position to the last known player location, but at a fixed height
	var player_pos = PlayerInfo.get_engine_player_position()
	cam.translation = player_pos
	cam.translation.y = CAMERA_HEIGHT
