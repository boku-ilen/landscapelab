extends Resource
class_name LayerResourceGroup


class LayerResourceContainer extends AbstractLayerSerializer.SerializationWrapper:
	var container := []
	
	static func get_class_name():
		return "LayerCompositionReference"


var name: String
var group: LayerResourceGroup
var layer_resources := LayerResourceContainer.new()
