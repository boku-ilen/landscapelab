extends SubViewportContainer


func _ready():
	# Bypass for issue #56502
	$SubViewport.handle_input_locally = false
	await get_tree().process_frame
	$SubViewport.handle_input_locally = true
	
	$SubViewport/GeoLayerRenderers.popup_clicked.connect(
		func():
			$SubViewport/Camera2D.dont_handle_next_release = true
	)
	
	var camera = $SubViewport/Camera2D
	$SubViewport/GeoLayerRenderers.apply_offset(Vector2.ZERO, camera.get_viewport_rect().size, camera.zoom)
