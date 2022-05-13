extends AbstractRequestHandler
class_name NewTokenRequestHandler

#
# Example request data:
# {
#    "keyword": "NEW_TOKEN",
#    "position_x": 123.0,
#    "position_y": 123.0,
#    "brick_color": "RED",
#    "brick_shape": "SQUARE"
# }
#

var table_communicator: TableCommunicator  # To be injected


# set the protocol keyword
func _init():
	protocol_keyword = "NEW_TOKEN"


func handle_request(request: Dictionary) -> Dictionary:
	var result = {
		"keyword": "TOKEN_ANSWER",
		"success": false,
		"object_id": 0
	}
	
	var collection = table_communicator.token_to_game_object_collection[request["brick_shape"]][request["brick_color"]]
	var new_game_object = GameSystem.create_new_game_object(
		collection, Vector3(request["position_x"], 0.0, -request["position_y"]))
	
	if new_game_object:
		result["success"] = true
		result["object_id"] = new_game_object.id
	
	return result
