extends AbstractPlayer


func _ready():
	# Setup VR
	var interface = ARVRServer.find_interface("OpenVR")
	if interface and interface.initialize():
		get_viewport().arvr = true
		get_viewport().keep_3d_linear = true
		get_viewport().hdr = true

		# Make sure vsync is disabled or we'll be limited to 60fps
		OS.vsync_enabled = false

		# Up our physics to 90fps to get in sync with our rendering
		# TODO: Is this needed?
		Engine.iterations_per_second = 90


func _process(delta):
	# Place on ground
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray($PlayerVR.global_transform.origin + Vector3(0, 5000, 0),
			$PlayerVR.global_transform.origin + Vector3(0, -5000, 0), [self])
	
	if result:
		$PlayerVR.global_transform.origin.y = result.position.y
