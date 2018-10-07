extends CheckButton

func _ready():
	logger.debug("ui initialize")
	self.connect("toggled", get_tree().get_root().get_node("main"), "_on_VRToggled")
	pass
