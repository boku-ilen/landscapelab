extends Node
class_name LabTableCommunicator

# The port we will listen to
const PORT = 14541

# Our WebSocketServer instance
var _server = WebSocketServer.new()

# For reacting to deleted bricks
var brick_id_to_position = {}

@export var save_log := true
@export var draw_layer_ui: DrawLayerUI

var current_log_file


func _ready():
	_server.client_connected.connect(_connected)
	
	_server.client_disconnected.connect(_disconnected)
	
	_server.message_received.connect(_on_data)
	
	var err = _server.listen(PORT)
	if err != OK:
		print("Unable to start server")
		set_process(false)
	
	get_parent().game_object_failed.connect(_on_game_object_creation_failed)
	
	if save_log:
		DirAccess.make_dir_absolute("user://table-log")
		var filename = "user://table-log/%s.log" % [Time.get_unix_time_from_system()]
		current_log_file = FileAccess.open(filename, FileAccess.WRITE)
		current_log_file.store_string("test")


func _connected(id):
	print("Client %d connected" % [id])


func _disconnected(id):
	print("Client %d disconnected" % [id])


func _on_data(id, message):
	if save_log:
		current_log_file.store_string(str(floor(Time.get_unix_time_from_system())) + ": " + message + "\n")
		current_log_file.flush()
	
	var data_dict = JSON.parse_string(message)
	var shape = ""
	var color = ""
	logger.info(data_dict["event"])
	if data_dict != null and data_dict["event"] != "drawing_processed" and data_dict["event"] != "drawing_done":
		logger.info("Got data from client %d: %s" % [id, data_dict])

		shape = data_dict["data"]["shape"]
		color = data_dict["data"]["color"]
	
	if shape in GameSystem.current_game_mode.token_to_game_object_collection \
			and color in GameSystem.current_game_mode.token_to_game_object_collection[shape]:
		get_parent().current_goc_name = GameSystem.current_game_mode.token_to_game_object_collection[shape][color]
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
			
		var event = InputEventMouseButton.new()
		event.pressed = true
		event.button_index = 1
		event.position = position_scaled
		event.global_position = position_scaled
		get_viewport().push_input(event, false)
		
		await get_tree().process_frame
		
		# Send a mouse release event immediately after
		var release_event = event.duplicate()
		release_event.pressed = false
		get_viewport().push_input(release_event, false)
	
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
			
			get_viewport().push_input(event, false)
			
			await get_tree().process_frame
			
			# Send a mouse release event immediately after
			var release_event = event.duplicate()
			release_event.pressed = false
			
			get_viewport().push_input(release_event, false)
			
			# Remove this brick from brick_id_to_position
			brick_id_to_position.erase(data_dict["data"]["id"])
			
	elif data_dict["event"] == "drawing_processed":
		
		var color_id = data_dict["data"]["id"]
		var bounding_box = data_dict["data"]["bounds"]
		var bitmap_resolution = data_dict["data"]["resolution"]
		var bitmap: String = data_dict["data"]["bitmap"]

		var window = get_viewport()
		var screen_size = Vector2(DisplayServer.screen_get_size(window.current_screen))
		var screen_pos = Vector2(bounding_box[0], bounding_box[1]) + 0.5 * Vector2(bounding_box[2], bounding_box[3])
		#var pixel_size = (Vector2(bitmap_resolution[0], bitmap_resolution[1]) / Vector2(bounding_box[3], bounding_box[2])) / screen_size
		#sprite_instance.scale = pixel_size
		var reference_image_size = Vector2(bitmap_resolution[0], bitmap_resolution[1]) / Vector2(bounding_box[2], bounding_box[3])
		get_parent().drawing_coordinator.handle_returned_drawing(color_id, screen_pos, (screen_size / reference_image_size).x, bitmap_resolution, bounding_box, bitmap.hex_decode())
		
	elif data_dict["event"] == "drawing_done":
		logger.info("received " + str(data_dict["data"]["number_of_results"]) + " drawings")
		get_parent().drawing_coordinator.handle_drawing_mode_end()


func _on_game_object_creation_failed(event_position):
	var id = null
	
	# The straightforward way would be this:
	# id = brick_id_to_position.find_key(event_position)
	# however, this doesn't seem to work, so we do it manually for the Vector2 components
	for brick_id in brick_id_to_position.keys():
		if brick_id_to_position[brick_id].x == event_position.x \
				and brick_id_to_position[brick_id].y == event_position.y:
			id = brick_id
	
	if id != null:
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

func request_drawing_capture():
	var samples = draw_layer_ui.get_sample_points()
	_server.send(0,JSON.stringify({
		"event": "start_drawing",
		"data": {
			"points": samples
		}
	}))
	logger.info("sent")
