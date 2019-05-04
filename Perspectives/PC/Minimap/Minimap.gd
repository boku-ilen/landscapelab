extends Spatial

#
# Basic minimap implementation which uses an orthographic camera placed above the player.
#

onready var cam = get_node("Camera")

var follow_mode
var ZOOM_STEP = 1000 # Settings.get_setting("minimap", "zoom_step")
var ZOOM_START = Settings.get_setting("minimap", "zoom_start")
var ZOOM_MAX = Settings.get_setting("minimap", "zoom_max")
var ZOOM_MIN = Settings.get_setting("minimap", "zoom_min")
var CAMERA_HEIGHT = Settings.get_setting("minimap", "height")

signal minimap_icon_resize(new_zoom)


func _ready():
	follow_mode = true
	change_size(ZOOM_START)
	GlobalSignal.connect("minimap_zoom_in", self, "zoom_in")
	GlobalSignal.connect("minimap_zoom_out", self, "zoom_out")
	GlobalSignal.connect("toggle_follow_mode", self, "toggle_follow_mode")
	GlobalSignal.connect("initiate_minimap_icon_resize", self, "relay_minimap_icon_resize")
	GlobalSignal.connect("request_minimap_icon_resize", self, "respond_to_minimap_icon_update_request")

# Changes the size of the minimap camera to the given 'size'.
# Size refers to the width/height of the camera making the orthographic projection.
# e.g. a size of 2000 results in a visible area of roughly 4000x3000.
func change_size(size):
	cam.size = size
	GlobalSignal.emit_signal("initiate_minimap_icon_resize", size, filename)


func _process(delta):
	# Set position to the last known player location, but at a fixed height
	var player_pos = PlayerInfo.get_engine_player_position()
	cam.translation = player_pos
	cam.translation.y = CAMERA_HEIGHT


# zoom in by ZOOM_STEP, typically triggered by the gui zoom in symbol
func zoom_in():
	if cam.size - ZOOM_STEP > ZOOM_MIN:
		change_size(cam.size - ZOOM_STEP)


# zoom out by ZOOM_STEP, typically triggered by the gui zoom out symbol 	
func zoom_out():
	if cam.size + ZOOM_STEP < ZOOM_MAX:
		change_size(cam.size + ZOOM_STEP)


# change the state of the follow mode
func toggle_follow_mode():
	follow_mode = !follow_mode


# sends signal with minimap size and status so that minimap icons can rescale accordingly
func relay_minimap_icon_resize(value, initiator):
	if initiator != filename:
		GlobalSignal.emit_signal("minimap_icon_resize", cam.size, value)


func respond_to_minimap_icon_update_request():
	GlobalSignal.emit_signal("initiate_minimap_icon_resize", cam.size, filename)