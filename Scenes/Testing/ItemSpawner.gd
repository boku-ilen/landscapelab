extends Spatial

var windmill_scene = preload("res://Scenes/Windmill.tscn")
var tree_scene = preload("res://Scenes/Tree.tscn")

onready var world = get_tree().get_root().get_node("TestWorld/TileSpawner")
onready var camera = get_parent()

const ray_length = 2000 # Distance that will be checked for collision with the ground

var settings
var building_settings
var dict
	
func _ready():
	settings = ServerConnection.getJson("127.0.0.1" ,"/location/areas/?filename=wullersdorf", 8000)
	building_settings = settings["buildings"]
	dict = ServerConnection.getJson("127.0.0.1", "/buildings/?filename=%s" % building_settings['filename'], 8000)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# Cast a ray to where the player is looking at
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * ray_length
		
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)
		
		if result: # We have a collision with the ground -> spawn a windmill (can be generified to any scene!)
			if event.button_index == 1: # Left click
				world.put_on_ground(windmill_scene.instance(), result.position)
			elif event.button_index == 2: # Right click
				world.put_on_ground(tree_scene.instance(), result.position)
			elif event.button_index == 3:
				world.put_on_ground(createBuilding("127.0.0.1", 8000, settings), result.position)
		else:
			print("No result!")
			
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