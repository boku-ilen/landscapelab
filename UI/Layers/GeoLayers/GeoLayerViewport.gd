extends SubViewportContainer


func _gui_input(event):
	$SubViewport/Camera2D.input(event)
	if has_node("ActionHandler"):
		$ActionHandler.handle(event)
