extends AbstractRequestHandler
class_name SetPositionRequestHandler

#
# Handles "set position" requests and sets the position checked the target node accordingly.
#
# Example request data:
# {
# "message_id": 1,
# "keyword": "TELEPORT_TO",
# "position": [420500, 453950]
# }
#


@export var target_path: NodePath
@onready var target = get_node(target_path)


# set the protocol keyword
func _init():
	protocol_keyword = "TELEPORT_TO"


func handle_request(request: Dictionary) -> Dictionary:
	if target:
		if target.has_method("set_true_position"):
			target.set_true_position(request.position)
			return {"success": true}
		else:
			logger.warn(
				"Target has no set_true_position method, can't convert to local coordinates!"
			)
	
	logger.warn("Invalid target in SetPositionRequestHandler, couldn't handle request!")
	return {"success": false}
