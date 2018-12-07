extends Label

func _process(delta):
	if delta > 0:
		text = "FPS: %d" % (1 / delta)