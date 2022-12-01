extends SubViewportContainer


func _gui_input(event):
	$SubViewport/Camera2D.input(event)


func _ready():
	$ZoomContainer/ZoomIn.pressed.connect($SubViewport/Camera2D.do_zoom.bind(1.1))
	$ZoomContainer/ZoomOut.pressed.connect($SubViewport/Camera2D.do_zoom.bind(0.9))
	
	
