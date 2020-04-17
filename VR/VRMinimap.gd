extends Camera

#
# Basic minimap implementation which uses an orthographic camera placed above the player.
#

onready var ray = get_node("RayCast")
onready var marker = get_node("MeshInstance")

var ZOOM_STEP = 1000 # Settings.get_setting("minimap", "zoom_step")
var ZOOM_START = Settings.get_setting("minimap", "zoom_start")
var ZOOM_MAX = Settings.get_setting("minimap", "zoom_max")
var ZOOM_MIN = Settings.get_setting("minimap", "zoom_min")
var CAMERA_HEIGHT = Settings.get_setting("minimap", "height")

signal minimap_icon_resize(new_zoom)


func _ready():
	change_size(ZOOM_START)
	GlobalSignal.connect("initiate_minimap_icon_resize", self, "relay_minimap_icon_resize")
	GlobalSignal.connect("request_minimap_icon_resize", self, "respond_to_minimap_icon_update_request")


# Changes the size of the minimap camera to the given 'size'.
# Size refers to the width/height of the camera making the orthographic projection.
# e.g. a size of 2000 results in a visible area of roughly 4000x3000.
func change_size(cam_size):
	size = cam_size


func _process(delta):
	# Set position to the last known player location, but at a fixed height
	var player_pos = PlayerInfo.get_engine_player_position()
	translation = player_pos
	translation.y = CAMERA_HEIGHT


func _input(event):
	if event is InputEventMouseMotion:
		# Direct the mouse position on the screen along the camera
		# We use a local ray since it should be relative to the rotation of any parent node
		var mouse_point_vector = project_local_ray_normal(event.position)
		
		# Transform the forward vector to this projected vector (-z is forward)
		ray.transform.basis.z = -mouse_point_vector
	elif event is InputEventMouseButton:
		if event.pressed:
			marker.global_transform.origin = ray.get_collision_point()
