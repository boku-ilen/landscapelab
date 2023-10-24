extends Node

# The port we will listen to
const PORT = 14541

# Our WebSocketServer instance
var _server = WebSocketServer.new()

var token_to_game_object_collection = {
	"BrickShape.SQUARE_BRICK": {
		"BrickColor.RED_BRICK": "test"
	}
}

func _ready():
	_server.client_connected.connect(_connected)
	_server.client_disconnected.connect(_disconnected)
	
	_server.message_received.connect(_on_data)
	
	var err = _server.listen(PORT)
	if err != OK:
		print("Unable to start server")
		set_process(false)


func _connected(id):
	print("Client %d connected" % [id])


func _disconnected(id):
	print("Client %d disconnected" % [id])


func _on_data(id, message):
	var data_dict = JSON.parse_string(message)
	print("Got data from client %d: %s" % [id, data_dict])
	
	if data_dict["event"] == "brick_added":
	
		var viewport_position = data_dict["data"]["position"]
		
		var shape = data_dict["data"]["shape"]
		var color = data_dict["data"]["color"]
		
		if shape in token_to_game_object_collection \
				and color in token_to_game_object_collection[shape]:
			var collection = token_to_game_object_collection[shape][color]
			
			var window = get_viewport()
			var screen_size = DisplayServer.screen_get_size(window.current_screen)
			
			var position_scaled = Vector2i(
					Vector2(viewport_position[0], viewport_position[1]) \
					* Vector2(screen_size)
			)
			
			var event = InputEventMouseButton.new()
			event.pressed = true
			event.button_index = 1
			event.position = position_scaled
			event.global_position = position_scaled
			
			get_viewport().push_input(event, true)
			
			# Send a mouse release event immediately after
			var release_event = event.duplicate()
			release_event.pressed = false
			
			get_viewport().push_input(release_event, true)
	
	elif data_dict["event"] == "brick_removed":
		
		pass


func _process(delta):
	_server.poll()
