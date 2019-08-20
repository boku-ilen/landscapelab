extends Spatial


#
# Keeps track of asset instances: Updates periodically and instanciates assets
# which weren't in the response previously, and removes assets which aren't in
# the response anymore.
# Optionally, if the 'moving' flag is true, the positions of already spawned 
# assets are also updated.
#


export(PackedScene) var asset_scene
export(bool) var moving = false  # If true, asset positions are updated continuously
export(float) var update_interval
export(float) var initial_update_delay = 0  # Wait for some time before making the first update

var _result
var _new_result = false
var _active = true

var time_to_update = 0


func _ready():
	# Start right now with the first update, or wait for initial_update_delay seconds
	time_to_update = update_interval - initial_update_delay
	
	Offset.connect("shift_world", self, "_on_shift_world")


# Update assets from now on
func _set_active():
	logger.debug("Asset handler %s got active!" % [name])
	_active = true


# Stop updating assets
func _set_inactive():
	logger.debug("Asset handler %s got inactive!" % [name])
	_active = false


func _process(delta):
	# If we're inactive, we shouldn't do anything
	if not _active:
		return
	
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

			if _result.has(asset_id):
				# If this asset is in the response, update it
				if moving:
					spawned_asset.translation = _get_engine_position_for_asset(asset_id)
			else:
				# If it's not in the response, it was deleted or is out of bounds -> remove it
				logger.debug("Removed asset instance with ID %s" % [asset_id])
				
				spawned_asset.queue_free()
		
		# Second: Iterate over all assets in the response. If it's not in the current assets, it is new -> spawn it
		for instance_id in _result:
			var instance_name = String(instance_id)

			if not has_node(instance_name):
				_spawn_asset(instance_id)
					
				logger.debug("Spawned new asset instance with ID %s" % [instance_name])
			
		# Start getting the next result
		_new_result = false
		
		
func _server_point_to_engine_pos(server_x, server_y):
	# Convert the 2D world position received from the server to in-engine 2D coordinates
	var instance_pos_2d = Offset.to_engine_coordinates([-server_x, server_y])
			
	# Convert to a 3D position by placing the point on the ground
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
	_result = _get_server_result()
	
	# TODO: Compare with previous result and only save updated fields for better efficiency
	
	# If the result is valid, set the flag
	if _result:
		_new_result = true


# Abstract function which returns the result (a list of assets) of the specific request being implemented.
func _get_server_result():
	return null


# Abstract function for getting the position of one asset in the result.
# Must be implemented for moving assets because different server responses have different formats of their data.
func _get_asset_position_from_response(asset_id):
	return [0, 0]


# Abstract function which instances the asset with the given asset_id.
func _spawn_asset(instance_id):
	pass


# Shortcut for _get_asset_position_from_response + _server_point_to_engine_pos
func _get_engine_position_for_asset(instance_id):
	var pos = _get_asset_position_from_response(instance_id)
	return _server_point_to_engine_pos(pos[0], pos[1])
	
	
# React to a world shift by moving all child nodes (asset instances) accordingly
func _on_shift_world(delta_x : int, delta_z : int):
	for child in get_children():
		child.translation += Vector3(delta_x, 0, delta_z)