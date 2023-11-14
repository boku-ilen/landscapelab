extends Node

# The port we will listen to
const PORT = 14541

# Our WebSocketServer instance
var _server = WebSocketServer.new()

var token_to_game_object_collection: Dictionary

# For reacting to deleted bricks
var brick_id_to_position = {}


func _ready():
	_server.client_connected.connect(_connected)
	_server.client_disconnected.connect(_disconnected)
	
	_server.message_received.connect(_on_data)
	
	var err = _server.listen(PORT)
	if err != OK:
		print("Unable to start server")
		set_process(false)
	
	get_parent().game_object_failed.connect(_on_game_object_creation_failed)


func _connected(id):
	print("Client %d connected" % [id])


func _disconnected(id):
	print("Client %d disconnected" % [id])


func _on_data(id, message):
	var data_dict = JSON.parse_string(message)
	print("Got data from client %d: %s" % [id, data_dict])
	
	var shape = data_dict["data"]["shape"]
	var color = data_dict["data"]["color"]
	
	if shape in token_to_game_object_collection \
			and color in token_to_game_object_collection[shape]:
		get_parent().current_goc_name = token_to_game_object_collection[shape][color]
	else:
		get_parent().current_goc_name = null
	
	if data_dict["event"] == "brick_added":
		var viewport_position = data_dict["data"]["position"]
		
		var window = get_viewport()
		var screen_size = DisplayServer.screen_get_size(window.current_screen)
		
		var position_scaled = Vector2i(
				Vector2(viewport_position[0], viewport_position[1]) \
				* Vector2(screen_size)
		)
			
		brick_id_to_position[data_dict["data"]["id"]] = position_scaled
			
		# First, delete anything that might have previously been at that position
		var event = InputEventMouseButton.new()
		event.pressed = true
		event.button_index = 2
		event.position = position_scaled
		event.global_position = position_scaled
		get_viewport().push_input(event, true)
		
		# Send a mouse release event immediately after
		var release_event = event.duplicate()
		release_event.pressed = false
		get_viewport().push_input(release_event, true)
		
		# Now, create a new object here
		var new_event = event.duplicate()
		event.button_index = 1
		get_viewport().push_input(event, true)
		
		var new_release_event = release_event.duplicate()
		new_release_event.button_index = 1
		get_viewport().push_input(new_release_event, true)
		#else:
			## This brick cannot be used - created an invalid marker
			#$LabTableMarkers.create_invalid_marker(position_scaled, data_dict["data"]["id"])
	
	elif data_dict["event"] == "brick_removed":
		# If this was an outdated brick, remove the invalid marker
		$LabTableMarkers.remove_marker(data_dict["data"]["id"])
		
		if brick_id_to_position.has(data_dict["data"]["id"]):
			var position_scaled = brick_id_to_position[data_dict["data"]["id"]]
			
			var event = InputEventMouseButton.new()
			event.pressed = true
			event.button_index = 2
			event.position = position_scaled
			event.global_position = position_scaled
			
			get_viewport().push_input(event, true)
			
			# Send a mouse release event immediately after
			var release_event = event.duplicate()
			release_event.pressed = false
			
			get_viewport().push_input(release_event, true)
			
			# Remove this brick from brick_id_to_position
			brick_id_to_position.erase(data_dict["data"]["id"])


func _on_game_object_creation_failed(event_position):
	var id
	
	# The straightforward way would be this:
	# id = brick_id_to_position.find_key(event_position)
	# however, this doesn't seem to work, so we do it manually for the Vector2 components
	for brick_id in brick_id_to_position.keys():
		if brick_id_to_position[brick_id].x == event_position.x \
				and brick_id_to_position[brick_id].y == event_position.y:
			id = brick_id
	
	if id:
		# This game object was created by a brick - create an invalid marker
		# It will be automatically removed when a brick_removed event arrives
		$LabTableMarkers.create_invalid_marker(event_position, id)
		
		# Remove this brick from brick_id_to_position since since no deletion query
		# will be required here
		brick_id_to_position.erase(id)


func _process(delta):
	_server.poll()


# Call this to persist previously placed bricks (removing a brick no longer
#  removes the corresponding game object).
func clear_brick_memory():
	# Add invalid markers for bricks which got invalid
	for brick_id in brick_id_to_position.keys():
		$LabTableMarkers.create_invalid_marker(brick_id_to_position[brick_id], brick_id)
	
	brick_id_to_position.clear()
