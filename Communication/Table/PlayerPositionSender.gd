extends Node

#
# Broadcasts changes in the player position via the CommunicationServer.
# Must be the child node of the player (the parent must have the function `get_world_position`)!
#


export var update_interval := 0.5

var _current_update_timer := 0.0
var _previous_player_position := [0.0, 0.0, 0.0]


func _process(delta):
	_current_update_timer += delta
	
	var new_player_position = get_parent().get_world_position()
	
	if (new_player_position[0] != _previous_player_position[0] \
			or new_player_position[2] != _previous_player_position[2]) \
			and _current_update_timer >= update_interval:
		_send_updated_position(new_player_position)
		_current_update_timer = 0.0
		_previous_player_position = new_player_position


func _send_updated_position(new_position):
	var message = {
		"keyword": "PLAYER_POS",
		"projected_x": new_position[0],
		"projected_y": new_position[2]
	}
	
	CommunicationServer.broadcast(message)
