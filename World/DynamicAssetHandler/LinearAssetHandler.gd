extends Spatial

export(PackedScene) var linear_drawer

var _result
var _new_result = false
var _active = true

var update_interval = 1000  # TODO Settings.get_setting("assets", "dynamic-update-interval")
var time_to_update = 990  # TODO


func _ready():
	Offset.connect("shift_world", self, "_on_shift_world")

	# Get the first result
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_get_lines_from_server", []))


func _process(delta):
	# If we're inactive, we shouldn't do anything
	if not _active:
		return
	
	# Increment the time to the next update; if a new update should now be done, do that in a thread
	time_to_update += delta
	
	if time_to_update >= update_interval:
		time_to_update = 0
		
		var player_pos = PlayerInfo.get_true_player_position()
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_get_lines_from_server", [-player_pos[0], player_pos[2]]), 80.0)
		
	# If there is a fresh valid result from the server, instantiate missing assets
	# and update all positions
	if _new_result and _result:
		for line_id in _result:
			var line = _result[line_id]["line"]
			var vectored_line = []
			
			for point in line:
				vectored_line.append(_convert_point_coordinates(point[0], point[1]))
				
			var drawer = linear_drawer.instance()
			drawer.name = line_id
			add_child(drawer)
			
			drawer.add_points(vectored_line)
			
		# Start getting the next result
		_new_result = false
		
		
func _convert_point_coordinates(x, y):
	# Convert the 2D world position received from the server to in-engine 2D coordinates
	var instance_pos_2d = Offset.to_engine_coordinates([-x, y])
			
	# Convert to a 3D position
	var instance_pos_3d = Vector3(instance_pos_2d.x, 0, instance_pos_2d.y)
	var ground_pos = WorldPosition.get_position_on_ground(instance_pos_3d)
	
	# There may not be a ground_pos if there is no valid collider at that position
	if ground_pos:
		return ground_pos
	else:
		return instance_pos_3d


# Loads a new asset instance result from the server (to be called from a thread)
func _get_lines_from_server(data):
	# Don't cache this since the result regularly changes
	# TODO: Currently only asset type 1
	_result = ServerConnection.get_json("/linear/%d.0/%d.0/1.json" % [data[0], data[1]], false)
	
	# TODO: Compare with previous result and only save updated fields
	
	# If the result is valid, set the flag
	if _result:
		_new_result = true
	
	
# React to a world shift by moving all child nodes (asset instances) accordingly
func _on_shift_world(delta_x : int, delta_z : int):
	for child in get_children():
		child.translation += Vector3(delta_x, 0, delta_z)