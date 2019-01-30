extends Spatial

#
# A node with this script can be instantiated as a child of the player's camera.
# Thus, any scene can be spawned on the ground of LOD-terrain at the position the camera's center points at.
# Currently, the spawned scenes are hardcoded, but this can be generified when needed.
#

var windmill_scene = preload("res://Scenes/Windmill.tscn")
var tree_scene = preload("res://Scenes/Tree.tscn")

onready var world = get_tree().get_root().get_node("TestWorld/TileSpawner") # Required for getting exact ground positions
onready var camera = get_parent()

var ray_length = Settings.get_setting("item-spawner", "camera-ray-length") # Distance that will be checked for collision with the ground

var locked_item = null
var last_mouse_pos = Vector3(0, 0, 0)

func _process(delta):
	if locked_item:
		var from = camera.project_ray_origin(last_mouse_pos)
		var to = from + camera.project_ray_normal(last_mouse_pos) * ray_length
		
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to, [locked_item.get_node("StaticBody")]) # TODO: This exception is ugly and will break!
		
		if result: # We have a collision with the ground -> spawn a windmill (can be generified to any scene!)
			locked_item.translation = world.get_ground_coords(result.position)

# This callback is called whenever any input is registered
# TODO: use actions instead of hard-coded mouse buttons
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# Cast a ray to where the player is looking at
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * ray_length
		
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)
		
		if result: # We have a collision with the ground -> spawn a windmill (can be generified to any scene!)
			if event.button_index == 1: # Left click
				if result.collider.is_in_group("Movable"):
					locked_item = result.collider.get_parent()
				else:
					world.put_on_ground(windmill_scene.instance(), result.position)
			elif event.button_index == 2: # Right click
				#lotsOfTrees(result.position)
				world.put_on_ground(tree_scene.instance(), result.position)
			elif event.button_index == 3: # Middle click
				world.put_on_ground(createBuilding("127.0.0.1", 8000, settings), result.position)
		else:
			print("No result!")
	elif event is InputEventMouseMotion:
		last_mouse_pos = event.position

# The following code will likely be moved to LOD terrain tiles later, since buildings will be spawned there, not by mouse clicks.
# It's currently here to test arbitrary building placement on LOD terrain.
var settings
var building_settings
var dict

func _ready():
	settings = ServerConnection.getJson("127.0.0.1" ,"/location/areas/?filename=wullersdorf", 8000)
	building_settings = settings["buildings"]
	dict = ServerConnection.getJson("127.0.0.1", "/buildings/?filename=%s" % building_settings['filename'], 8000)

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