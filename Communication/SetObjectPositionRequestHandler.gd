extends AbstractRequestHandler
class_name SetObjectPositionRequestHandler

#
# Handles "get object layer data" requests and returns all data within the requested object layer.
#
# Example request data:
# {
# "message_id": 1,
# "keyword": "SET_OBJECT_POSITION",
# "layer_name": "wind_turbines",
# "object_id": 12,
# "position": [123, 123]
# }
#


# set the protocol keyword
func _init():
	protocol_keyword = "SET_OBJECT_POSITION"


func handle_request(request: Dictionary) -> Dictionary:
	var result = {"success": false}
	var layer = Layers.get_layer(request.layer_name)
	
	if layer:
		var feature = layer.get_feature_by_id(request.object_id)
		
		if feature:
			result.success = true
			feature.set_vector3(Vector3(request.position[0], 0.0, request.position[1]))
	
	return result
