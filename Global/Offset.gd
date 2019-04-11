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


func to_engine_coordinates(pos):
	if pos is Array and pos.size() == 2:
		return Vector2(x - pos[0], -pos[1] + z)
	elif pos is Array and pos.size() == 3:
		return Vector3(x - pos[0], pos[1], -pos[2] + z)
	else:
		logger.warning("Invalid type for to_engine_coordinates: %s;"\
			+ "Needs to be Array with length of 2 or 3" % [String(typeof(pos))])
