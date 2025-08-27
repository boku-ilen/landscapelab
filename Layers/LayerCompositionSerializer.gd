extends AbstractLayerSerializer
class_name LayerCompositionSerializer


func _init() -> void:
	base_render_info = LayerComposition.RenderInfo

# override default arg
static func deserialize(
		abs_path: String, composition_name: String, 
		data: Dictionary, 
		layer_composition := LayerComposition.new(),
		serializer = LayerCompositionSerializer) -> Variant:
	
	return super.deserialize(abs_path, composition_name, data, layer_composition, serializer)


static func get_render_info_from_config(type: String, layer_resource: Resource) -> RefCounted:
	var layer_composition = layer_resource as LayerComposition
	return layer_composition.RENDER_INFOS[type].new()


static func dictify(layer_resource: Variant, attributes: Dictionary) -> Dictionary:
	var layer_composition = layer_resource as LayerComposition
	return {
		layer_composition.name: {
			"type": layer_composition.render_info.get_class_name(),
			"attributes": attributes
		}
	}
