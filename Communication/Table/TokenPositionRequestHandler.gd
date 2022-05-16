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
		"placement_allowed": false,
		"object_id": 0
	}
	
	var game_object = GameSystem.get_game_object(request["object_id"])
	
	if game_object:
		# TODO: Verify if placement is actually allowed at that new position
		# (Doesn't matter along as Table only sends Creations and Deletes)
		game_object.set_position(Vector3(
			request["position_x"], 0.0, -request["position_y"]
		))
		
		result["object_id"] = game_object.id
		result["placement_allowed"] = true
	
	return result
