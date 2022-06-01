extends ViewportContainer


# to be injected from above
var pc_player: AbstractPlayer setget set_player


func set_player(p: AbstractPlayer):
	pc_player = p
	$Viewport/RemoteTransform.remote_path = p.get_path()


func _ready():
	$ZoomContainer/ZoomIn.connect("pressed", self, "zoom", [100.0])
	$ZoomContainer/ZoomOut.connect("pressed", self, "zoom", [-100.0])


func zoom(zoom_factor: float):
	$Viewport/RemoteTransform/Camera.size += zoom_factor


func _process(delta):
	$Viewport/PlayerMarker.rotation.y = -pc_player.get_look_direction().signed_angle_to(Vector3.FORWARD, Vector3.UP)
	
	$Viewport/PlayerMarker.transform.origin = Vector3(
			pc_player.transform.origin.x, 
			$Viewport/PlayerMarker.transform.origin.y,
			pc_player.transform.origin.z)
