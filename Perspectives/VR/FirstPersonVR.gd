extends Spatial

#
# This script sets up the VR player, as described in
# https://github.com/GodotVR/godot-openvr-asset.
#

func _ready():
	var interface = ARVRServer.find_interface("OpenVR")
	
	if interface and interface.initialize():
		# turn off vsync, we'll be using the headsets vsync
		OS.vsync_enabled = false
			
		# change our physics fps
		Engine.target_fps = 90
	
		# make sure HDR rendering is off (not applicable for GLES2 renderer)
		get_viewport().hdr = false
		
		logger.info("Successfully initialized VR")
	else:
		logger.error("Couldn't initialize VR headset! Is it connected and SteamVR running for OpenVR?")
