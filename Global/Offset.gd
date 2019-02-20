extends Node

var x : int = 0
var z : int = 0

signal shift_world

func _ready():
	connect("shift_world", self, "_on_shift_world")
	
func _on_shift_world(delta_x : int, delta_z : int):
	x += delta_x
	z += delta_z
	
	print("New offset: %d, %d" % [x, z])

func set_offset(new_x, new_z):
	x = new_x
	z = new_z
	
func to_world_coordinates(pos):
	if pos is Vector2:
		return [x - int(pos.x), z - int(pos.y)]
	elif pos is Vector3:
		return [x - int(pos.x), int(pos.y), z - int(pos.z)]
	else:
		logger.warning("Invalid type for to_world_coordinates: %s;"\
			+ "supported types: Vector2, Vector3" % [typeof(pos)])