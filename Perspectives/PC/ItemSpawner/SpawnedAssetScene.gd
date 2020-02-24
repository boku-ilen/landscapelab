extends Spatial


export(int) var asset_id: int
export(Vector3) var collision_point
export(Array) var global_collision_point: Array

var is_valid: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(collision_point != null)
	assert(global_collision_point != null)
	assert(asset_id != null)
	
	add_child(Assets.get_asset_instance(asset_id))
	get_child(0).translation = WorldPosition.get_position_on_ground(collision_point)
	
	
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "add_object_on_server",
		[global_collision_point[0], global_collision_point[2]]), 99)


func _process(_delta):
	if not is_valid:
		queue_free()


# Registers a new asset instance at the position data[0], data[1] on the server (to be called from a thread)
func add_object_on_server(data):
	var result = ServerConnection.get_json("/assetpos/create/%d/%d/%d.0/%d.0" % [Session.scenario_id, asset_id, -data[0], data[1]])
	
	if not result.creation_success: 
		is_valid = false
		logger.error("Object could with asset ID %d could not be created." [asset_id])
	else:
		name = String(result.assetpos_id)
		logger.error("Object with asset ID %d successfully created" [asset_id])
		#material_overide = Assets.get_asset_material(asset_id)
