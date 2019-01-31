extends Spatial

#
# A node with this script can be instantiated as a child of the player's camera.
# Thus, any scene can be spawned on the ground of LOD-terrain at the position the camera's center points at.
# Currently, the spawned scenes are hardcoded, but this can be generified when needed.
#

var spawned_scene = preload("res://Scenes/Windmill.tscn")
var tree_scene = preload("res://Scenes/Tree.tscn")

onready var world = get_tree().get_root().get_node("TestWorld/TileSpawner") # Required for getting exact ground positions
onready var camera = get_parent()
onready var cursor = get_node("InteractRay")

var ray_length = Settings.get_setting("item-spawner", "camera-ray-length") # Distance that will be checked for collision with the ground

var locked_object = null

func _ready():
	cursor.cast_to = Vector3(0, 0, -ray_length)

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
				world.put_on_ground(spawned_scene.instance(), cursor.get_collision_point())

func grab_object_at_cursor():
	locked_object = cursor.get_collider().get_parent() # TODO: Would be great to make this more generic... perhaps add a script in the StaticBody to get the main object?
	cursor.add_exception(cursor.get_collider())
	
func update_grabbed_object():
	if cursor.is_colliding(): # Reposition the grabbed object to the spot on the ground the cursor points at
		locked_object.translation = world.get_ground_coords(cursor.get_collision_point())
	
func release_object():
	locked_object = null
	cursor.clear_exceptions()
	
func has_grabbed_object():
	return locked_object != null

# The following code will likely be moved to LOD terrain tiles later, since buildings will be spawned there, not by mouse clicks.
# It's currently here to test arbitrary building placement on LOD terrain.
var settings
var building_settings
var dict

#func _ready():
#	settings = ServerConnection.getJson("127.0.0.1" ,"/location/areas/?filename=wullersdorf", 8000)
#	building_settings = settings["buildings"]
#	dict = ServerConnection.getJson("127.0.0.1", "/buildings/?filename=%s" % building_settings['filename'], 8000)

func lotsOfTrees(pos):
	for x in range(-10, 10):
		for y in range(-10, 10):
			var add = 0.5 - randf()
			
			var vec = Vector3(x + add, 0, y + add) * 50
			
			world.put_on_ground(tree_scene.instance(), pos + vec)
	
func createBuilding(server, port, settings):
	if dict == null:
		ErrorPrompt.show("Could not load building data")
	elif dict.has("Error"):
		ErrorPrompt.show("Could not load building data", dict["Error"])
	else:
		var b = dict['Data'][randi() % dict['Data'].size()]
		
		for i in range(b['coordinates'].size()):
			for j in range(b['coordinates'][i].size()):
				# 594373 is an offset that works well for putting these building meshes at approx. their local 0 vector
				b['coordinates'][i][j] = Vector3(b['coordinates'][i][j][0] - 594373, 0, b['coordinates'][i][j][1] - 594373)
		
		var building = load("res://Scenes/Building.tscn")
		building = building.instance()
		building.init(b)
		
		return building