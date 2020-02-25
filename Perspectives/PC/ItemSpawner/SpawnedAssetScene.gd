extends Spatial

#
# This node's purpose is for a quicker response when adding assets to the world
# manually. To get a fee
#

export(int) var asset_id: int
export(Material) var temporary_material = preload("res://Materials/DebugPink.tres")
export(Vector3) var collision_point
export(Array) var global_collision_point: Array

var is_valid: bool = true
var instance: Node

# Called when the node enters the scene tree for the first time. As this node will 
# firstly be instanced in the itemspawner scene, we want to add the assets instance
# only when it enters the node, not on ready as this will cause problems with the
# position.
func _enter_tree():
	assert(collision_point != null)
	assert(global_collision_point != null)
	assert(asset_id != null)
	
	instance = Assets.get_asset_instance(asset_id)
	add_child(instance)
	
	global_transform.origin = collision_point
	
	# Give the thread a higher priority for a quicker response if asset is valid
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "add_object_on_server",
		[global_collision_point[0], global_collision_point[2]]), 99)


# Set the material in the ready function to make sure all the child nodes (possible meshes)
# are set aleady.
func _ready():
	set_asset_material(instance, temporary_material)


func _process(_delta):
	if not is_valid:
		queue_free()


# Registers a new asset instance at the position data[0], data[1] on the server (to be called from a thread)
func add_object_on_server(data):
	var result = ServerConnection.get_json("/assetpos/create/%d/%d/%d.0/%d.0" % [Session.scenario_id, asset_id, -data[0], data[1]])
		
		# As the server request takes some time we instance a scene for the time we are waiting for a result
		# - Sucessful: the node will be renamed with the given id of the server
		# 		which was sent in the json. Thus the assethandler will 
		# 		not instanciate a second asset at the given position.
		# - Unsucessful: The attached node with the temporary asset will be removed.
	
	if not result.creation_success: 
		is_valid = false # Set a flag as queue_free() from a thread is dangerous
		logger.error("Object could with asset ID %d could not be created." [asset_id])
	else:
		name = String(result.assetpos_id)
		logger.error("Object with asset ID %d successfully created" [asset_id])
		set_asset_material(instance, null)


# Recursively set the material of a node and its children VisualInstances
func set_asset_material(node: Node, material: Material):
	if node is VisualInstance:
		node.material_override = material
	
	for child in node.get_children():
		set_asset_material(child, material)
