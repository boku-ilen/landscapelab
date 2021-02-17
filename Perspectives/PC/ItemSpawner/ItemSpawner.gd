extends Spatial

#
# A node with this script can be instantiated as a child of the player's camera.
# Thus, any scene can be spawned on the ground of LOD-terrain at the position the camera's center points at.
# Currently, the spawned scenes are hardcoded, but this can be generified when needed.
#


export(int) var spawned_id = 1
export(Material) var until_response_material

onready var cursor: RayCast = get_parent().get_node("InteractRay")

# FIXME: These do not exist at that path anymore, and hard-coded paths like these are bad.
#  We will likely be able to remove them once we restructured the asset handling without
#  the server.
onready var world = get_tree().get_root().get_node("Main/TileHandler")
onready var asset_handler_parent = get_tree().get_root().get_node("Main/AssetHandlerSpawner")

var locked_object = null
var enabled_input_controller = false

var pos_manager: PositionManager


func _ready():
	# Connect signal to set the according itemID
	GlobalSignal.connect("changed_asset_id", self, "set_spawned_id")
	GlobalSignal.connect("input_controller", self, "set_input_controller_mode", [true])
	GlobalSignal.connect("stop_sync_moving_assets", self, "set_input_controller_mode", [false])
	GlobalSignal.connect("sync_moving_assets", self, "set_input_controller_mode", [false])


# This callback is called whenever any input is registered
func _unhandled_input(event):
	# just perform any action if the input mode is set to controller
	if enabled_input_controller:
		if event.is_action_pressed("object_interact"):
			if cursor.is_colliding():
				if cursor.get_collider().is_in_group("Movable"): # Player clicked on a movable object -> delete it
					# MovableObjects always have the root one layer above the StaticBody which is collided with,
					#  and that root has the ID of itself as its name
					var movable_object = cursor.get_collider().get_parent()
					var collided_id = int(movable_object.name)
					
					if collided_id != 0:
						delete_asset(collided_id)
					else:
						logger.warning("Asset %s has an invalid name, couldn't be cast to int!" % [movable_object.name])
				
				else:
					var collision_point = cursor.get_collision_point()
					var global_collision_point = pos_manager.to_world_coordinates(collision_point)
					
					# As the server request takes some time we instance a scene for the time we are waiting for a result
					# - Sucessful: the node will be renamed with the given id of the server
					# 		which was sent in the json. Thus the assethandler will 
					# 		not instanciate a second asset at the given position.
					# - Unsucessful: The attached node with the temporary asset will be removed.
					
					var asset_scene = load("res://Perspectives/PC/ItemSpawner/SpawnedAssetScene.tscn").instance()
					asset_scene.asset_id = spawned_id
					asset_scene.global_collision_point = global_collision_point
					asset_scene.collision_point = WorldPosition.get_position_on_ground(collision_point)
					# The asset handler's name for a given asset is a string of the assets id 
					asset_handler_parent.get_node(String(spawned_id)).add_child(asset_scene)
					
					logger.info("Adding asset instance with ID %d" % [spawned_id])


# Enqueues the server request for deleting the object with the given ID.
func delete_asset(id):
	logger.info("Removing asset instance with ID %d" % [id])
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "delete_object_on_server", [id]))


# Actually sends the server request for deleting an object (to be called from a thread)
func delete_object_on_server(data):
	#FIXME: it is currently unresolved how we can get rid of a connection like this as
	#FIXME: we need to syncronize the asset positions with the labtable and maybe other
	#FIXME: external displays like QGIS
	# ServerConnection.get_json("/assetpos/remove/%d" % [data[0]])


# Sets the id for the spawned item which is clicked in the ui controller
func set_spawned_id(id):
	spawned_id = id


# sets the mode of the input controller
func set_input_controller_mode(enabled):
	enabled_input_controller = enabled
	logger.debug("set controller input mode to %s" % [enabled_input_controller])
