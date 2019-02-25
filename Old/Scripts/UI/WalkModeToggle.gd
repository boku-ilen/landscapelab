extends CheckButton

func _ready():
	var camera = get_tree().get_root().get_node("main/ViewportContainer/DesktopViewport/Camera")
	self.connect("toggled", camera, "set_walk_mode")
	#logger.info("walk mode toggle initialized")