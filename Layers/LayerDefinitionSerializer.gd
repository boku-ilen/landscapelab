extends AbstractLayerSerializer
class_name LayerDefinitionSerializer


func _init() -> void:
	base_render_info = RefCounted

# override default arg
static func deserialize(
		abs_path: String, definition_name: String, 
		type: Variant, attributes: Dictionary, 
		layer_definition := LayerDefinition.new(),
		serializer = LayerDefinitionSerializer) -> Variant:
	
	return super.deserialize(abs_path, definition_name, type, attributes, layer_definition, serializer)


static func get_render_info_from_config(type: Variant, layer_resource: Resource) -> RefCounted:
	return LayerDefinition.RasterRenderInfo.new() if type == LayerDefinition.TYPE.RASTER \
			else LayerDefinition.FeatureRenderInfo.new()


static func dictify(layer_resource: Variant, attributes: Dictionary) -> Dictionary:
	var layer_composition = layer_resource as LayerComposition
	return {
		layer_composition.name: {
			"type": layer_composition.render_info.get_class_name(),
			"attributes": attributes
		}
	}
