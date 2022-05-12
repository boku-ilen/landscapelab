extends AbstractRequestHandler
class_name RemoveTokenRequestHandler

#
# Example request data:
# {
#    "keyword": "REMOVE_TOKEN",
#    "object_id": 0
# }
#

var table_communicator: TableCommunicator  # To be injected


# set the protocol keyword
func _init():
	protocol_keyword = "REMOVE_TOKEN"


func handle_request(request: Dictionary) -> Dictionary:
	var result = {
		"keyword": "TOKEN_ANSWER",
		"success": false,
		"object_id": 0
	}
	
	var game_object = GameSystem.get_game_object(request["object_id"])
	
	if game_object:
		GameSystem.remove_game_object(game_object)
		
		result["success"] = true
		result["object_id"] = game_object.id
	
	return result
