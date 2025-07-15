extends BoxContainer


@export var camera_2d: Camera2D :
	set(new_camera_2d):
		camera_2d = new_camera_2d
		get_node("ZoomIn").pressed.connect(camera_2d.do_zoom.bind(1))
		get_node("ZoomOut").pressed.connect(camera_2d.do_zoom.bind(-1))
