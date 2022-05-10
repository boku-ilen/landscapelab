extends AbstractRequestHandler
class_name TokenPositionRequestHandler

#
# Example request data:
# {
#    "keyword": "SET_TOKEN_POSITION",
#    "object_id": 0,
#    "position_x": 123.0,
#    "position_y": 123.0
# }
#

var table_communicator: TableCommunicator  # To be injected


# set the protocol keyword
func _init():
	protocol_keyword = "SET_TOKEN_POSITION"


func handle_request(request: Dictionary) -> Dictionary:
	var result = {
		"keyword": "TOKEN_ANSWER",
		"success": false,
		"object_id": 0
	}
	
	var game_object = GameSystem.get_game_object(request["object_id"])
	
	game_object.set_position(Vector3(
		request["position_x"], 0.0, -request["position_y"]
	))
	
	return result
