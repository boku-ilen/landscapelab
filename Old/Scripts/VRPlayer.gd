extends Viewport

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	
	#setting up vr
	var interface = ARVRServer.find_interface("Oculus")
	if interface and interface.initialize():
		pass
	else:
		interface = ARVRServer.find_interface("OpenVR")
		if interface and interface.initialize():
			pass
		else:
			logger.info("no VR headset found, removing VRPlayer")
			queue_free()
	
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
