extends Node

@export var main_viewport: SubViewport

@export var fps_when_vr_used := 5
@export var viewport_downscale_when_vr_used := 0.5


func _ready():
	$FPSTimer.timeout.connect(set_new_frame)
	
	var xr_interface = XRServer.find_interface("OpenXR")
	
	xr_interface.session_visible.connect(_on_openxr_visible_state)
	xr_interface.session_focussed.connect(_on_openxr_focused_state)


func _on_openxr_visible_state():
	# User took off VR headset -> maximize framerate
	$FPSTimer.stop()
	main_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	main_viewport.scaling_3d_scale = 1.0


func _on_openxr_focused_state():
	# User put on VR headset -> limit main viewport framerate
	$FPSTimer.timeout = 1.0 / float(fps_when_vr_used)
	$FPSTimer.start()
	main_viewport.scaling_3d_scale = viewport_downscale_when_vr_used


func set_new_frame():
	main_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
