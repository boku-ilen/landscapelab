extends Spatial

var windmill_scene = preload("res://Scenes/Windmill.tscn")
var tree_scene = preload("res://Scenes/Tree.tscn")

onready var world = get_tree().get_root().get_node("TestWorld/TileSpawner")
onready var camera = get_parent()

const ray_length = 2000 # Distance that will be checked for collision with the ground

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
		else:
			print("No result!")