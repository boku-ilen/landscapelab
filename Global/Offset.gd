extends Node

#
# This script handles the conversion between engine coordinates (what Godot is using in the game world)
# and world coordinates (the absolute webmercator coordinates corresponding to these engine coordinates).
# It provides a signal that should be called when shifting the world, and reacted to in all nodes which
# need to react to this shift (e.g. to keep their position at the correct location).
#

var x : int = 0
var z : int = 0

signal shift_world


func _ready():
	connect("shift_world", self, "_on_shift_world")


# Updates the current divergence between engine coordinates and world coordinates.
# Called automatically when the 'shift_world' signal is emitted.
func _on_shift_world(delta_x : int, delta_z : int):
	x += delta_x
	z += delta_z
	
	logger.debug("New offset: %d, %d" % [x, z])


# Sets the current divergence between engine coordinates and world coordinates.
func set_offset(new_x, new_z):
	x = new_x
	z = new_z
	
	logger.debug("New offset: %d, %d" % [x, z])


# Converts engine coordinates to world coordinates (absolute webmercator coordinates).
# Works with Vector2 (top view) and Vector3.
func to_world_coordinates(pos):
	if pos is Vector2:
		return [x - int(pos.x), z - int(pos.y)]
	elif pos is Vector3:
		return [x - int(pos.x), int(pos.y), z - int(pos.z)]
	else:
		logger.warning("Invalid type for to_world_coordinates: %s;"\
			+ "supported types: Vector2, Vector3" % [typeof(pos)])

# Converts world coordinates (absolute webmercator coordinates) to engine coordinates.
# Works with Vector2 (top view) and Vector3.
func to_engine_coordinates(pos):
	if pos is Array and pos.size() == 2:
		return Vector2(x - pos[0], -pos[1] + z)
	elif pos is Array and pos.size() == 3:
		return Vector3(x - pos[0], pos[1], -pos[2] + z)
	else:
		logger.warning("Invalid type for to_engine_coordinates: %s;"\
			+ "Needs to be Array with length of 2 or 3" % [String(typeof(pos))])
