extends SubViewportContainer


var pos_manager: PositionManager :
	get:
		return pos_manager
	set(new_manager):
		pos_manager = new_manager
		$SubViewport/GeoLayerRenderers.pos_manager = new_manager


func _ready():
	$ZoomContainer/ZoomIn.pressed.connect($SubViewport/Camera2D.zoom_in.bind(0.5))
	$ZoomContainer/ZoomOut.pressed.connect($SubViewport/Camera2D.zoom_out.bind(0.5))
