extends Spatial

#
# Raycasts down to check for collisions in the given range and displays them in the 3D world.
# Waits for the set delay since it may take some time for tiles to spawn.
#


var start_x = -10000
var end_x = 10000
var start_y = -10000
var end_y = 10000

var step = 100

var marker = preload("res://Util/Debug/DebugMarker.tscn")

var delay = 5
var current_time = 0
var done = false



func _ready():
	Offset.connect("shift_world", self, "_on_shift_world")



func _on_shift_world(delta_x : int, delta_z : int):
	for child in get_children():
		child.translation += Vector3(delta_x, 0, delta_z)



func _process(delta):
	current_time += delta
	
	if current_time > delay and not done:
		done = true
		
		for x in range(start_x, end_x, step):
			for y in range(start_y, end_y, step):
				var space_state = get_world().direct_space_state
				var result = space_state.intersect_ray(Vector3(x, 5000, y), Vector3(x, 0, y))
				
				if result:
					var mark = marker.instance()
					mark.translation = result.position
					add_child(mark)
