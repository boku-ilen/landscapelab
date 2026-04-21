extends Node

@export var main_viewport: SubViewport


func _ready():
	$FPSTimer.timeout.connect(set_new_frame)
	
	var xr_interface = XRServer.find_interface("OpenXR")
	
	xr_interface.session_visible.connect(_on_openxr_visible_state)
	xr_interface.session_focussed.connect(_on_openxr_focused_state)


func _on_openxr_visible_state():
	# User took off VR headset -> maximize framerate
	$FPSTimer.stop()
	main_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _on_openxr_focused_state():
	# User put on VR headset -> limit main viewport framerate
	$FPSTimer.start()


func set_new_frame():
	main_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
