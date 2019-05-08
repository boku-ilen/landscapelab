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


func _ready():
	Offset.connect("shift_world", self, "_on_shift_world")
	
	# Get the first result
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_get_asset_instances", []))
	
	
func _process(delta):
	# If there is a fresh result from the server, instantiate missing assets and update
	# all positions
	if _new_result:
		# If the result was valid, handle it
		if _result:
			for instance_id in _result["assets"]:
				var instance_name = String(instance_id)
	
				if not has_node(instance_name):
					var new_instance = asset_scene.instance()
					new_instance.name = instance_name
					add_child(new_instance)
					
				var instance = get_node(instance_name)
	
				# FIXME: It seems like we need to correct this value with GRIDSIZE / 2 below.
				# This should be tested more, and possibly adjusted in the Offset.to_engine_coordinates function!
				var instance_pos_2d = Offset.to_engine_coordinates([-_result["assets"][instance_id]["position"][0],
					_result["assets"][instance_id]["position"][1]])
				
				# Place the instance on the ground if possible
				var instance_pos_3d = Vector3(instance_pos_2d.x, 1500, instance_pos_2d.y)
				var ground_pos = WorldPosition.get_position_on_ground(instance_pos_3d)
				
				if ground_pos: # There may not be a ground_pos if there is no valid collider at that position
					instance.translation = ground_pos
				else:
					instance.translation = instance_pos_3d
			
		# Start getting the next result
		_new_result = false
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_get_asset_instances", []))
	

# Loads a new asset instance result from the server (to be called from a thread)
func _get_asset_instances(data):
	# Don't cache this since the result regularly changes
	_result = ServerConnection.get_json("/assetpos/get_all/%d.json" % [asset_id], false)
	_new_result = true
	
	
# React to a world shift by moving all child nodes (asset instances) accordingly
func _on_shift_world(delta_x : int, delta_z : int):
	for child in get_children():
		child.translation += Vector3(delta_x, 0, delta_z)