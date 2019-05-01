extends Spatial

#
# Basic minimap implementation which uses an orthographic camera placed above the player.
#

onready var cam = get_node("Camera")

var camera_height
var follow_mode
var CAMERA_SIZE = Settings.get_setting("minimap", "size")
var ZOOM_STEP = 1000 # Settings.get_setting("minimap", "zoom_step")
var ZOOM_MAX = Settings.get_setting("minimap", "zoom_max")
var ZOOM_MIN = Settings.get_setting("minimap", "zoom_min")


func _ready():
	follow_mode = true
	camera_height = Settings.get_setting("minimap", "height")
	change_size(CAMERA_SIZE)
	GlobalSignal.connect("minimap_zoom_in", self, "zoom_in")
	GlobalSignal.connect("minimap_zoom_out", self, "zoom_out")
	GlobalSignal.connect("toggle_follow_mode", self, "toggle_follow_mode")


# Changes the size of the minimap camera to the given 'size'.
# Size refers to the width/height of the camera making the orthographic projection.
# e.g. a size of 2000 results in a visible area of roughly 4000x3000.
func change_size(size):
	cam.size = size


func _process(delta):
	# Set position to the last known player location, but at a fixed height
	var player_pos = PlayerInfo.get_engine_player_position()
	cam.translation = player_pos
	cam.translation.y = camera_height


# FIXME: this implementation does not work (because of the ortho projection?)
# zoom in by ZOOM_STEP, typically triggered by the gui zoom in symbol
func zoom_in():
	if camera_height - ZOOM_STEP > ZOOM_MIN:
		camera_height = camera_height - ZOOM_STEP


# zoom out by ZOOM_STEP, typically triggered by the gui zoom out symbol 	
func zoom_out():
	if camera_height + ZOOM_STEP < ZOOM_MAX:
		camera_height = camera_height + ZOOM_STEP


# change the state of the follow mode
func toggle_follow_mode():
	follow_mode = !follow_mode
