extends SubViewportContainer


var pos_manager: PositionManager :
	get:
		return pos_manager
	set(new_manager):
		pos_manager = new_manager
		$SubViewport/GeoLayerRenderers.pos_manager = new_manager


func _gui_input(event):
	$SubViewport/Camera2D.input(event)


func _ready():
	$ZoomContainer/ZoomIn.pressed.connect($SubViewport/Camera2D.do_zoom.bind(1.1))
	$ZoomContainer/ZoomOut.pressed.connect($SubViewport/Camera2D.do_zoom.bind(0.9))
	
	
