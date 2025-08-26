extends Object
class_name AbstractLayerSerializer

# Wrapper class for serialization logic
class SerializationWrapper:
	# To be overridden
	static func get_class_name() -> String:
		# Fake abstract class behavior
		logger.warn("Abstract classes function of \"SeralizationWrapper\" was called")
		assert(false, "Abstract class")
		return "SerializationWrapper"


# to be overwritten by inheriting class
static var base_render_info = RefCounted.new()

static var deserialization_lookup = {
	"GeoRasterLayer": 
		func(attribute, abs_path, serializer):
			# easy reference to pre existing
			if attribute in Layers.geo_layers["features"]:
				return Layers.geo_layers["features"][attribute]
			
			return get_geolayer_from_path(abs_path, attribute, "GeoRasterLayer"),
	"GeoFeatureLayer": 
		func(attribute, abs_path, serializer):
			# easy reference to pre existing
			if attribute in Layers.geo_layers["features"]:
				return Layers.geo_layers["features"][attribute]
			
			if attribute is Dictionary and attribute["_type"] == "virtual":
				attribute = get_virtual_layer(abs_path, attribute)
			else:
				attribute = get_geolayer_from_path(abs_path, attribute, "GeoFeatureLayer")
			return attribute,
	"Texture": func(attribute, abs_path, serializer): return load(attribute),
	"Texture2D": func(attribute, abs_path, serializer): return load(attribute),
	"Gradient": 
		func(attribute, abs_path, serializer):
			if not attribute in ColorRamps.gradients:
				assert(false, "Not implemented yet")
			return ColorRamps.gradients[attribute],
	"LayerCompositionReference":
		func(attribute, abs_path, serializer):
			if not attribute in Layers.layer_compositions: 
				logger.error("Wrong configuration, LayerComposition with name %s could not be found.")
				return
			
			var reference = LayerDefinition.LayerCompositionReference.new()
			reference.composition_name = attribute
			return reference,
	"LayerResourceContainer":
		func(layers_dict, abs_path, serializer):
			var layer_resources_container = LayerResourceGroup.LayerResourceContainer.new()
			for layer_name in layers_dict:
				var l = serializer.deserialize(abs_path, layer_name, layers_dict[layer_name])
				layer_resources_container.container.append(l)
				if l is LayerComposition: 
					Layers.add_layer_composition(l)
				elif l is LayerDefinition: 
					Layers.add_layer_definition(l)
				
			return layer_resources_container
}
static func deserialize(
		abs_path: String, name: String, 
		data: Dictionary, 
		layer_resource, # layer is either a layer_composition or layer_definition
		serializer): # gdscript does not support static polymorphism, we need to give the context, see https://github.com/godotengine/godot/issues/72973
	var raw_type: String = data["type"]
	var attributes: Dictionary = data["attributes"]
	
	# TODO: we could potentially refactor this in away that serialization is fully independent
	# of the underlying type. This would require a major restructure of the config however.
	if raw_type == "Group":
		var group := LayerResourceGroup.new()
		group.name = name
		group = Serialization.deserialize(attributes, group, abs_path, _lookup_deserialization.bind(serializer, layer_resource))
		group.layer_resources.container.map(func(lr): lr.group = group)
		Layers.add_layer_group(group)
		return group
	
	var type = serializer.interpret_type(raw_type, name)
	layer_resource.name = name
	layer_resource.render_info = serializer.get_render_info_from_config(type, layer_resource)
	
	layer_resource.render_info = Serialization.deserialize(attributes, layer_resource.render_info, abs_path, _lookup_deserialization.bind(serializer, layer_resource))
	layer_resource.ui_info = Serialization.deserialize(attributes, layer_resource.ui_info, abs_path, _lookup_deserialization.bind(serializer, layer_resource))
	
	return layer_resource


static var serialization_lookup = {
	"GeoRasterLayer": 
		func(property_var): return "{}:{}?{}".format(
			[property_var.get_dataset().get_file_info()["path"],
			property_var.get_file_info()["name"],
			"w" if property_var.get_dataset().has_write_access() else "r"], "{}"),
	"GeoFeatureLayer": 
		func(property_var): return "{}:{}?{}".format(
			[property_var.get_file_info()["path"],
			property_var.get_file_info()["name"],
			"w" if property_var.get_dataset().has_write_access() else "r"], "{}"),
	"Color": 
		func(property_var): return str(property_var)
}
static func serialize(layer_resource):
	# Create list of basic Object properties so we can ignore those later
	var base_property_names = []
	for property in base_render_info.get_property_list():
		base_property_names.append(property["name"])
		
	var attributes = {}
	for property in layer_resource.render_info.get_property_list():
		# Ignore basic Object properties
		if property["name"] in base_property_names: continue
		var type = property["type"]
		if property["type"] == TYPE_OBJECT:
			type = property["class_name"]
		
		var property_var = layer_resource.render_info.get(property["name"])
		var serialized = property_var
		if type in serialization_lookup:
			serialized = serialization_lookup[type].call(property_var)
	
		attributes[property["name"]] = serialized 
	
	return dictify(layer_resource, attributes)


static func _lookup_deserialization(config_attribute, render_info_attribute, info, abs_path, serializer, layer_res=null):
	# Check if it is a class name (e.g. GeoRasterLayer or GeoFeatureLayer do have as they are
	# gdnative objects)
	if render_info_attribute["class_name"] in deserialization_lookup:
		var deserializer_func = deserialization_lookup[render_info_attribute["class_name"]]
		return deserializer_func.call(config_attribute, abs_path, serializer)
	
	# If the to be configured attribute in the render_info is not an object, deserialization
	# needs to be trivial, otherwise it needs to be wrapped
	if render_info_attribute.type != TYPE_OBJECT:
		return
	# Do a default serialization
	if not info.get(render_info_attribute.name) is SerializationWrapper:
		return Serialization.deserialize(
			config_attribute, 
			layer_res.render_info.get(render_info_attribute["name"]), 
			abs_path, 
			serializer._lookup_deserialization.bind(serializer, layer_res)
		)
	
	# The lookup the class name in the lookup dictionary
	var lookup_string = info.get(render_info_attribute.name).call("get_class_name")
	if lookup_string in deserialization_lookup:
		var deserializer_func = deserialization_lookup[lookup_string]
		return deserializer_func.call(config_attribute, abs_path, serializer)


# to be implemented by sub-class
static func get_render_info_from_config(type: String, layer: Resource) -> RefCounted:
	return RefCounted.new()


# to be implemented by sub-class
# final step, as it is written into the serialized config
static func dictify(layer: Variant, attributes: Dictionary) -> Dictionary:
	return {}


static func get_geolayer_from_path(abs_path: String, attribute_name: String, cls_name: String):
	# Split data into {LL_xy.gpkg, layer_name, write_access}
	var splits = LLFileAccess.split_dataset_string(abs_path, attribute_name)
	
	if cls_name == "GeoRasterLayer":
		return LLFileAccess.get_layer_from_splits(splits, true)
	elif cls_name == "GeoFeatureLayer":
		return LLFileAccess.get_layer_from_splits(splits, false)
	
	return null


static func get_virtual_layer(abs_path: String, sub_config: Dictionary) -> GeoFeatureLayer:
	var splits = LLFileAccess.split_dataset_string(abs_path, sub_config["dataset"])
	
	var geo_ds = Geodot.get_dataset(
		splits["file_name"], splits["write_access"])
	
	return geo_ds.get_sql_feature_layer(sub_config["sql_query"])


static func get_feature_layer_from_string(path_string, abs_path):
	var path_layer_split = path_string.split(":")
	# => ["ortho", "w"]
	var layer_access_split = path_layer_split[1].split("?")
	var abs_file_name = LLFileAccess.get_rel_or_abs_path(abs_path, path_layer_split[0])
	var layer_name = layer_access_split[0]
	var write_access = true if layer_access_split.size() > 1 and layer_access_split[1] == "w" else false
	
	var db = Geodot.get_dataset(abs_file_name, write_access)
	
	return db.get_feature_layer(layer_name)


static func interpret_type(type: String, name: String):
	return type
