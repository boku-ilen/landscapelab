extends Resource
class_name LayerResourceGroup


class LayerResourceContainer extends AbstractLayerSerializer.SerializationWrapper:
	var container := []
	
	static func get_class_name():
		return "LayerResourceContainer"

signal visibility_changed(visible)

var is_visible: bool = true : set=set_is_visible
var name: String
var group: LayerResourceGroup
var layer_resources := LayerResourceContainer.new()


func set_is_visible(new_is_visible: bool):
	is_visible = new_is_visible
	layer_resources.container.map(func(l): l.is_visible = new_is_visible)
	visibility_changed.emit(new_is_visible)
