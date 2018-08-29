extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func update_preview_size():
	var new_size = OS.window_size
	$ViewportContainer/DesktopViewport.size = new_size

func _ready():
	# init our viewport size and register resize 
	update_preview_size()
	get_tree().get_root().connect("size_changed", self, "update_preview_size")
	
	logger.set_filename("log.txt")
	pass



func _process(delta):
	pass




func _on_VRToggled(turned_on):
	if turned_on:
		logger.info("turning VR on")
		
		#instantiate VRPlayer
		var VRPlayer = preload("res://Scenes/VRPlayer.tscn").instance()
		add_child(VRPlayer)
	else:
		logger.info("turning VR off")
		
		#remove VRPlayer
		var VRPlayer = get_node("VRViewport")
		if VRPlayer:
			VRPlayer.queue_free()
	
	pass # replace with function body
