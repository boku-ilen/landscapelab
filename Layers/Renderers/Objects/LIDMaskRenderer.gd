extends FeatureLayerCompositionRenderer
class_name LIDMaskRenderer

var instance_mapping: Dictionary

func _ready():
	radius = layer_composition.render_info.radius
	
	# "Pre"load instances to save time during instantiation (duplicate with FLAG=5)
	for key in layer_composition.render_info.objects:
		instance_mapping[key] = load(layer_composition.render_info.objects[key]).instantiate()
	
	super._ready()

func load_feature_instance(feature: GeoFeature) -> Node3D:
	var instance_key = "default"
	# If selector attribute is set and we find an object then overwrite
	var selector_attrib = layer_composition.render_info.selector_attribute_name
	if feature.get_attribute(selector_attrib) in layer_composition.render_info.objects:
		instance_key = feature.get_attribute(selector_attrib)
	
	var instance = instance_mapping[instance_key].duplicate(5)
	instance.name = str(feature.get_id())
	var local_pos = feature.get_offset_vector3(-center[0], 0, -center[1])
	instance.transform.origin = local_pos
	
	return instance
