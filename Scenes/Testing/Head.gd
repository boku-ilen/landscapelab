extends Spatial

var windmill_scene = preload("res://Scenes/Windmill.tscn")
onready var world = get_tree().get_root().get_node("TestWorld")

const ray_length = 2000

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var camera = $Camera
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * ray_length
		
		var space_state = get_world().direct_space_state
		
		var result = space_state.intersect_ray(from, to)
		
		if result:
			print(result.position)
			
			var windmill = windmill_scene.instance()
			windmill.translation = result.position
			world.add_child(windmill)
		else:
			print("No result!")