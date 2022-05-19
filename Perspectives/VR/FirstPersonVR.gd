extends AbstractPlayer


func _ready():
	# Setup VR
	var interface = ARVRServer.find_interface("OpenVR")
	if interface and interface.initialize():
		# Make sure vsync is disabled or we'll be limited to 60fps
		OS.vsync_enabled = false

		# Up our physics to 90fps to get in sync with our rendering
		# TODO: Is this needed?
		Engine.iterations_per_second = 90


func _process(delta):
	# Place on ground
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(Vector3(0, 5000, 0), Vector3(0, -5000, 0), [self])
	
	if result:
		transform.origin.y = result.position.y


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pc_move_left"):
		transform.origin.x -= 2.0
	elif event.is_action_pressed("pc_move_right"):
		transform.origin.x += 2.0
	elif event.is_action_pressed("pc_move_up"):
		transform.origin.z -= 2.0
	elif event.is_action_pressed("pc_move_down"):
		transform.origin.z += 2.0


func get_world_position():
	return position_manager.to_world_coordinates(translation)


func set_world_position(world_position):
	var new_pos = position_manager.to_engine_coordinates(world_position)
	translation.x = new_pos.x
	translation.z = new_pos.z
