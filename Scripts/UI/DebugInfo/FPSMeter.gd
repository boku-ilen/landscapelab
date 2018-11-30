extends Label

func _process(delta):
	text = "FPS: %d" % (1 / delta)