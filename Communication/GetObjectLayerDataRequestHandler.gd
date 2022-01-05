extends AbstractRequestHandler
class_name GetObjectLayerDataRequestHandler

#
# Handles "get object layer data" requests and returns all data within the requested object layer.
#
# Example request data:
# {
# "message_id": 1,
# "keyword": "GET_OBJECT_LAYER_DATA"
# "layer_name": "wind_turbines"
# }
#


# set the protocol keyword
func _init():
	protocol_keyword = "GET_OBJECT_LAYER_DATA"


func handle_request(request: Dictionary) -> Dictionary:
	var result = {"success": false}
	var layer = Layers.get_layer(request["layer_name"])
	
	if layer:
		result["success"] = true
		result["objects"] = []
		
		var features = layer.get_all_features()
		
		for feature in features:
			result["objects"].append({
				"attributes": feature.get_attributes(),
				"position": feature.get_vector3()
			})
	
	return result
