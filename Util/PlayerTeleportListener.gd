extends Spatial


#
# Regularly polls the server for whether there is a new player teleport point and,
# if so, teleports the player.
#


export(int) var player_teleporter_id

# TODO: Abstract this type of regular request into a separate node
var update_interval = 2
var timer = 0

var has_new_data = false  # Set to true when the server request is done so we can do the rest of the work in the main thread
var previous_request_done = false  # Used to prevent enqueueing tasks even though the previous one isn't done yet
var data  # The server response
var previous_teleport_point  # The previous teleport point - if equal to the new one, we don't need to do anything


func _ready():
	# Request the first data so that we have a previous_teleport_point and don't teleport to the position which
	#  was already on the server before we started this session
	_request_data([])
	previous_teleport_point = _get_teleport_point_from_response(data)


# Extracts the teleport point (2-dimensional array) from a properly formatted server response
func _get_teleport_point_from_response(response):
	var id = response["assets"].keys()[0]
	return response["assets"][id]["position"]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if has_new_data:
		has_new_data = false
		
		var new_teleport_point = _get_teleport_point_from_response(data)
		
		# If the new teleport point is different, teleport there
		if new_teleport_point[0] != previous_teleport_point[0] \
			or new_teleport_point[1] != previous_teleport_point[1]:
			_teleport_player(new_teleport_point)
			previous_teleport_point = new_teleport_point
	
	timer += delta
	
	if timer > update_interval and previous_request_done:
		get_new_data()
		timer = 0
		previous_request_done = false


# Enqueues a new server request
func get_new_data():
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_request_data", []), 80.0)


# Requests new data and sets the corresponding flags when done (to be called from a thread)
func _request_data(args):
	data = ServerConnection.get_json("/assetpos/get_all/%d.json" % [player_teleporter_id], false)  # Don't cache
	has_new_data = true
	previous_request_done = true


# Teleports the player to a point which was received by the server (formatted in webmercator coordinates)
func _teleport_player(point):
	# TODO: Add this to a global function - confusing negations because of different coordinate systems
	var point_fixed_coordinate = [-point[0], point[1]]
	var local_point = Offset.to_engine_coordinates(point_fixed_coordinate)
	var local_point_3d = Vector3(local_point.x, 0, local_point.y)
	
	PlayerInfo.update_player_pos(WorldPosition.get_position_on_ground(local_point_3d))
