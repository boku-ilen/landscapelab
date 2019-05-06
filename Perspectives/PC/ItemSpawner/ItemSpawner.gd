extends Spatial

#
# A node with this script can be instantiated as a child of the player's camera.
# Thus, any scene can be spawned on the ground of LOD-terrain at the position the camera's center points at.
# Currently, the spawned scenes are hardcoded, but this can be generified when needed.
#

export(int) var spawned_id = 1

onready var world = get_tree().get_root().get_node("Main/TileHandler") # Required for getting exact ground positions
onready var cursor = get_node("InteractRay")

var RAY_LENGTH = Settings.get_setting("item-spawner", "camera-ray-length") # Distance that will be checked for collision with the ground

var locked_object = null


func _ready():
	cursor.cast_to = Vector3(0, 0, -RAY_LENGTH)


func _process(delta):
	if has_grabbed_object():
		update_grabbed_object()


# This callback is called whenever any input is registered
func _input(event):
	if event.is_action_pressed("object_interact"):
		if cursor.is_colliding():
			if has_grabbed_object(): # We have a locked item -> release it to make it stationary and free the cursor
				release_object()
			
			elif cursor.get_collider().is_in_group("Movable"): # Player clicked on a movable object -> lock it to the cursor
				grab_object_at_cursor()
			
			else:
				var collision_point = cursor.get_collision_point()
				var global_collision_point = Offset.to_world_coordinates(collision_point)
				
				# TODO: It might take a while until the object is added on the server and instanced by the
				# DynamicAssetHandler. Thus, we might want to instance a scene here, which is replaced by
				# the real asset once the request is done (since the request will likely succeed - if not,
				# the placeholder asset will simply be removed and not replaced)
				
				ThreadPool.enqueue_task(ThreadPool.Task.new(self, "add_object_on_server",
					[global_collision_point[0], global_collision_point[2]]))
				

# Registers a new asset instance at the position data[0], data[1] on the server (to be called from a thread)
func add_object_on_server(data):
	ServerConnection.get_json("/assetpos/create/%d/%d.0/%d.0" % [spawned_id, -data[0], data[1]])


# Bind an object to the cursor (the mouse position)
func grab_object_at_cursor():
	# TODO: Make this asset not put itself at the server position while it's being dragged!
	# (Likely also requires a change in DynamicAssetHandler)
	
	locked_object = cursor.get_collider().get_parent() # TODO: Would be great to make this more generic... perhaps add a script in the StaticBody to get the main object?
	cursor.add_exception(cursor.get_collider())


# Update the position of the grabbed object based on the cursor
func update_grabbed_object():
	if cursor.is_colliding(): # Reposition the grabbed object to the spot on the ground the cursor points at
		locked_object.translation = world.get_ground_coords(cursor.get_collision_point())


# Place the grabbed object (making it stationary again)
func release_object():
	# TODO: Update position on server!
	
	locked_object = null
	cursor.clear_exceptions()


# Returns true if the cursor is currently grabbing an object (moving it with its movement)
func has_grabbed_object():
	return locked_object != null
