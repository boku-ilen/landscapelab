extends Label

func _process(delta):
	text = "Objects: %d" % get_tree().get_node_count()
	pass
