extends AbstractRequestHandler
class_name RemoveTokenRequestHandler

#
# Example request data:
# {
#    "keyword": "SET_TOKEN_POSITION",
#    "object_id": 0
# }
#


# set the protocol keyword
func _init():
	protocol_keyword = "REMOVE_TOKEN"


func handle_request(request: Dictionary) -> Dictionary:
	var result = {
		"keyword": "TOKEN_ANSWER",
		"success": false,
		"object_id": 0
	}
	
	return result
