extends AbstractRequestHandler
class_name CreateFeatureRequestHandler

#
# Handles "create feature" requests: creates a new feature an returns its ID
#
# Example request data:
# {
# "message_id": 1,
# "keyword": "CREATE_FEATURE",
# "layer_name": "wind_turbines"
# }
#


# set the protocol keyword
func _init():
	protocol_keyword = "CREATE_FEATURE"


func handle_request(request: Dictionary) -> Dictionary:
	var result = {"success": false}
	var layer = Layers.get_layer(request.layer_name)
	
	if layer:
		var feature = layer.create_feature()
		
		if feature:
			result.id = feature.get_id()
			result.success = true
	
	return result
