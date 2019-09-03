extends Spatial

#
# This script sets up the VR player, as described in
# https://github.com/GodotVR/godot-openvr-asset.
#


var interface


func _ready():
	interface = ARVRServer.find_interface("OpenVR")
	
	if interface and interface.initialize():
		# turn off vsync, we'll be using the headsets vsync
		OS.vsync_enabled = false
		
		# change our physics fps
		Engine.target_fps = 90
		
		# make sure HDR rendering is off (not applicable for GLES2 renderer), VR rendering is true
		# TODO: Ideally the VR player inherits from AbstractPlayer, which already handles this!
		logger.debug("Setting up viewport for VR")
		
		get_viewport().hdr = false
		get_viewport().arvr = true
		
		logger.info("Successfully initialized VR")
	else:
		logger.error("Couldn't initialize VR headset! Is it connected and SteamVR running for OpenVR?")


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Destructor: Uninitialize the VR interface
		interface.uninitialize()
