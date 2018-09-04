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
		
		#set vr camera mimicing on
		get_node("ViewportContainer/DesktopViewport/Camera").set_vrmode(true)
	else:
		logger.info("turning VR off")
		
		#set vr camera mimicing off
		var VRPlayer = get_node("VRViewport")
		if VRPlayer:
			VRPlayer.queue_free()
		
		get_node("ViewportContainer/DesktopViewport/Camera").set_vrmode(false)
	
	pass # replace with function body
