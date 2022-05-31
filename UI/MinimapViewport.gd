extends ViewportContainer


# to be injected from above
var pc_player: AbstractPlayer setget set_player


func set_player(p: AbstractPlayer):
	$Viewport/RemoteTransform.remote_path = p.get_path()


func _ready():
	$ZoomContainer/ZoomIn.connect("pressed", self, "zoom", [100.0])
	$ZoomContainer/ZoomOut.connect("pressed", self, "zoom", [-100.0])


func zoom(zoom_factor: float):
	$Viewport/RemoteTransform/Camera.size += zoom_factor
