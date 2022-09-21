extends AbstractRequestHandler
class_name SetTableExtentRequestHandler

#
# Handles "set position" requests and sets the position checked the target node accordingly.
#


@export var target: NodePath


# set the protocol keyword
func _init():
	protocol_keyword = "TABLE_EXTENT"
	LOG_MODULE = "TABLE"


func handle_request(request: Dictionary) -> Dictionary:
	if get_node(target):
		if get_node(target).has_method("set_true_position"):
			get_node(target).set_true_position(request.position)
			return {"success": true}
		else:
			logger.warn(
				"Target has no set_true_position method, can't convert to local coordinates!", LOG_MODULE
			)
	
	logger.warn("Invalid target in SetPositionRequestHandler, couldn't handle request!", LOG_MODULE)
	return {"success": false}
