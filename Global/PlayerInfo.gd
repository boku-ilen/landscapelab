extends Node

var last_player_pos = Vector3(0, 0, 0)
var last_player_look_direction = Vector3(0, 0, 0)

func update_player_pos(new_pos):
	last_player_pos = new_pos
	
func update_player_look_direction(new_dir):
	last_player_look_direction = new_dir
	
func add_player_pos(add_pos):
	update_player_pos(last_player_pos + add_pos)
	
func get_true_player_position():
	return Offset.to_world_coordinates(last_player_pos)
	
func get_engine_player_position():
	return last_player_pos
	
func get_player_look_direction():
	return last_player_look_direction