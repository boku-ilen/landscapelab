extends Label

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var camera

func _ready():
	camera = get_tree().get_root().get_node("main/ViewportContainer/DesktopViewport/Camera")
	camera.connect("position_updated", self, "set_pos")
	
	pass

func set_pos():
	text = "Position: %s" % camera.transform.origin

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
