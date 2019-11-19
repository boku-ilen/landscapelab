extends Node

#
# This Singleton provices access to the player position to all scripts which need it.
# The main player controller must update this node with the latest player position regularly.
#

# Emitted whenever the global player position is updated.
# Also emits the new engine position.
signal player_position_changed
signal player_look_direction_changed

var last_player_pos: Vector3 = Vector3(0, 0, 0)
var last_player_look_direction: Vector3 = Vector3(0, 0, 0)

var is_follow_enabled: bool = true
var is_main_active: bool = false

var walk_speed: float = 10


# Set the engine player position to a new Vector3
func update_player_pos(new_pos):
	last_player_pos = new_pos
	emit_signal("player_position_changed", last_player_pos)


# Set the player look direction to a new Vector3
func update_player_look_direction(new_dir):
	last_player_look_direction = new_dir
	emit_signal("player_look_direction_changed", last_player_look_direction)


# Adds a Vector3 to the last engine player position
func add_player_pos(add_pos):
	update_player_pos(last_player_pos + add_pos)


# Returns the last known player position in absolute webmercator world coordinates
func get_true_player_position():
	return Offset.to_world_coordinates(last_player_pos)


# Returns the last known player position in engine coordinates
func get_engine_player_position():
	return last_player_pos


# Returns the last known player look direction
func get_player_look_direction():
	return last_player_look_direction
