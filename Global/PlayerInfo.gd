extends Node

var last_player_pos = Vector3(0, 0, 0)
var last_player_offset_x : int = 0
var last_player_offset_y : int = 0

signal shift_world

func update_player_pos(new_pos):
	last_player_pos = new_pos
	
func add_player_pos(add_pos):
	update_player_pos(last_player_pos + add_pos)
	
func update_player_offset(new_offset_x, new_offset_y):
	last_player_offset_x = new_offset_x
	last_player_offset_y = new_offset_y
	
func add_player_offset(add_offset_x, add_offset_y):
	update_player_offset(last_player_offset_x + add_offset_x, last_player_offset_y + add_offset_y)
	
func get_true_player_position():
	return [int(last_player_pos.x) - last_player_offset_x, int(last_player_pos.y), int(last_player_pos.z) - last_player_offset_y]
	
func get_engine_player_position():
	return last_player_pos
	
func get_player_offset():
	return [last_player_offset_x, last_player_offset_y]