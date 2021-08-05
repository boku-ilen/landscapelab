extends AbstractRequestHandler
class_name SetTableExtentRequestHandler

#
# Handles "set position" requests and sets the position on the target node accordingly.
#


export(NodePath) var target


# set the protocol keyword
func _init():
	protocol_keyword = "TABLE_EXTENT"


func handle_request(request: Dictionary) -> Dictionary:
	if target:
		if target.has_method("set_true_position"):
			target.set_true_position(request.position)
			return {"success": true}
		else:
			logger.warning("Target has no set_true_position method, can't convert to local coordinates!")
	
	logger.warning("Invalid target in SetPositionRequestHandler, couldn't handle request!")
	return {"success": false}
