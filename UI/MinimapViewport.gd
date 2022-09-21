extends SubViewportContainer


@export var player_marker_scale := 0.0035
@export var min_zoom := 0.0
@export var max_zoom := 5000.0
@export var zoom_step := 100.0

@onready var zoom_factor = 1000.0 :
	get:
		return zoom_factor # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_zoom
@onready var marker = $SubViewport/PlayerMarker
# to be injected from above
var pc_player: AbstractPlayer :
	get:
		return pc_player # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_player


func set_zoom(zoom: float):
	if zoom > min_zoom and zoom < max_zoom: 
		zoom_factor = zoom
		marker.scale = Vector3.ONE * zoom_factor * player_marker_scale
		$SubViewport/Camera3D.size = zoom_factor


func set_player(p: AbstractPlayer):
	pc_player = p


func _ready():
	$ZoomContainer/ZoomIn.connect("pressed",Callable(self,"zoom").bind(zoom_step))
	$ZoomContainer/ZoomOut.connect("pressed",Callable(self,"zoom").bind(-zoom_step))
	set_zoom(zoom_factor)


func zoom(zoom: float):
	set_zoom(zoom_factor + zoom)


func _process(delta):
	# Only update the orientation in a 2Dish manner (only update north, east, south, west)
	marker.rotation.y = -pc_player.get_look_direction().signed_angle_to(Vector3.FORWARD, Vector3.UP)
	# And the position
	marker.transform.origin = Vector3(
			pc_player.transform.origin.x, 
			marker.transform.origin.y,
			pc_player.transform.origin.z)
			
	$SubViewport/Camera3D.transform.origin = Vector3(
			pc_player.transform.origin.x, 
			$SubViewport/Camera3D.transform.origin.y,
			pc_player.transform.origin.z)
