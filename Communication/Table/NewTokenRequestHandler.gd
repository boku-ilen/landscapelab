extends AbstractRequestHandler
class_name NewTokenRequestHandler

#
# Example request data:
# {
#    "keyword": "NEW_TOKEN",
#    "position": [123.0, 123.0],
#    "brick_color": "RED",
#    "brick_shape": "SQUARE"
# }
#


# set the protocol keyword
func _init():
	protocol_keyword = "NEW_TOKEN"


func handle_request(request: Dictionary) -> Dictionary:
	var result = {
		"keyword": "TOKEN_ANSWER",
		"success": false,
		"object_id": 0
	}
	
	return result
