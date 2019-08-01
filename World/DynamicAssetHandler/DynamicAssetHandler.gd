extends Spatial


#
# This node keeps track of the instances of a given asset. If a new
# one is created on the server, it is instantiated here. For this, the
# assets registered on the server are periodically checked.
# The positions of the asset instances are also updated here.
#


export(int) var asset_id
export(PackedScene) var asset_scene

var _assets = {}
var _result
var _new_result = false

var update_interval = 1
var time_to_update = 0


func _ready():
	Offset.connect("shift_world", self, "_on_shift_world")
	
	# Get the first result
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_get_asset_instances", []))
	
	
func _process(delta):
	# Increment the time to the next update; if a new update should now be done, do that in a thread
	time_to_update += delta
	
	if time_to_update >= update_interval:
		time_to_update = 0
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_get_asset_instances", []), 80.0)
		
	# If there is a fresh valid result from the server, instantiate missing assets
	# and update all positions
	if _new_result and _result:
		# First: Iterate over all assets currently spawned.
		for spawned_asset in get_children():
			var asset_id = spawned_asset.name

			if _result["assets"].has(asset_id):
				# If this asset is in the response, update it
				spawned_asset.translation = _get_position_for_asset(_result, asset_id)
			else:
				# If it's not in the response, it was deleted -> delete it
				spawned_asset.queue_free()
		
		# Second: Iterate over all assets in the response. If it's not in the current assets, it is new -> spawn it
		for instance_id in _result["assets"]:
			var instance_name = String(instance_id)

			if not has_node(instance_name):
				var new_instance = asset_scene.instance()
				new_instance.name = instance_name
				
				var pos = _get_position_for_asset(_result, instance_id)
				
				if pos.length() < 5000:
					new_instance.translation = pos
				
					add_child(new_instance)
			
		# Start getting the next result
		_new_result = false
		
		
func _get_position_for_asset(result, instance_id):
	# Convert the 2D world position received from the server to in-engine 2D coordinates
	var instance_pos_2d = Offset.to_engine_coordinates([-_result["assets"][instance_id]["position"][0],
				_result["assets"][instance_id]["position"][1]])
			
	# Convert to a 3D position by placing the asset on the ground
	var instance_pos_3d = Vector3(instance_pos_2d.x, 0, instance_pos_2d.y)
	var ground_pos = WorldPosition.get_position_on_ground(instance_pos_3d)
	
	# There may not be a ground_pos if there is no valid collider at that position
	if ground_pos:
		return ground_pos
	else:
		return instance_pos_3d


# Loads a new asset instance result from the server (to be called from a thread)
func _get_asset_instances(data):
	# Don't cache this since the result regularly changes
	_result = ServerConnection.get_json("/assetpos/get_all/%d.json" % [asset_id], false)
	
	# TODO: Compare with previous result and only save updated fields
	
	_new_result = true
	
	
# React to a world shift by moving all child nodes (asset instances) accordingly
func _on_shift_world(delta_x : int, delta_z : int):
	for child in get_children():
		child.translation += Vector3(delta_x, 0, delta_z)