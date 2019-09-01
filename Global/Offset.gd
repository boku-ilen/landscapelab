extends Node

#
# This script handles the conversion between engine coordinates (what Godot is using in the game world)
# and world coordinates (the absolute webmercator coordinates corresponding to these engine coordinates).
# It provides a signal that should be called when shifting the world, and reacted to in all nodes which
# need to react to this shift (e.g. to keep their position at the correct location).
#

var x : int = 0
var z : int = 0

var world_shift_check_period = 1
var world_shift_timer = 0

# When a player coordinate gets bigger than this, the world will be shifted to get the player back to the world origin
var shift_limit = Settings.get_setting("lod", "world-shift-distance")

signal shift_world


func _ready():
	connect("shift_world", self, "_on_shift_world")


func _process(delta):
	# Periodically check whether we need to shift the world
	world_shift_timer += delta
	
	if world_shift_timer > world_shift_check_period:
		world_shift_timer = 0
		check_for_world_shift()


# Shift the world if the player exceeds the bounds, in order to prevent coordinates from getting too big (floating point issues)
func check_for_world_shift():
	var delta_vec = Vector3(0, 0, 0)
	var player_pos = PlayerInfo.get_engine_player_position()
	
	# Check x, z coordinates
	delta_vec.x = -shift_limit * floor(player_pos.x / shift_limit)
	delta_vec.z = -shift_limit * floor(player_pos.z / shift_limit)
	# (Height (y) probably doesn't matter, height differences won't be that big
	
	# Apply
	if delta_vec != Vector3(0, 0, 0):
		Offset.emit_signal("shift_world", delta_vec.x, delta_vec.z)


# Updates the current divergence between engine coordinates and world coordinates.
# Called automatically when the 'shift_world' signal is emitted.
func _on_shift_world(delta_x : int, delta_z : int):
	x += delta_x
	z += delta_z
	
	PlayerInfo.add_player_pos(Vector3(delta_x, 0, delta_z))
	
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
