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
		func(attribute, abs_path):
			# easy reference to pre existing
			if attribute in Layers.geo_layers["features"]:
				return Layers.geo_layers["features"][attribute]
			
			return get_geolayer_from_path(abs_path, attribute, "GeoRasterLayer"),
	"GeoFeatureLayer": 
		func(attribute, abs_path):
			# easy reference to pre existing
			if attribute in Layers.geo_layers["features"]:
				return Layers.geo_layers["features"][attribute]
			
			if attribute is Dictionary and attribute["_type"] == "virtual":
				attribute = get_virtual_layer(abs_path, attribute)
			else:
				attribute = get_geolayer_from_path(abs_path, attribute, "GeoFeatureLayer")
			return attribute,
	"Texture": func(attribute, abs_path): return load(attribute),
	"LayerCompositionReference":
		func(attribute, abs_path):
			if not attribute in Layers.layer_compositions: 
				logger.error("Wrong configuration, LayerComposition with name %s could not be found.")
				return
			
			var reference = LayerDefinition.LayerCompositionReference.new()
			reference.composition_name = attribute
			return reference
}
static func deserialize(
		abs_path: String, name: String, 
		type: Variant, attributes: Dictionary, 
		layer_resource, # layer is either a layer_composition or layer_definition
		serializer): # gdscript does not support static polymorphism, we need to give the context, see https://github.com/godotengine/godot/issues/72973
	
	layer_resource.name = name
	layer_resource.render_info = serializer.get_render_info_from_config(type, layer_resource)
	
	var render_properties = {}
	for property in layer_resource.render_info.get_property_list():
		render_properties[property["name"]] = property
	
	for attribute_name in attributes:
		if not attribute_name in render_properties:
			logger.warn("An attribute \"%s\" was found for \"%s\" in the config file, 
				but it is not a valid property of that resource" % [attribute_name, name])
			continue
		
		var config_attribute = attributes[attribute_name]
		var render_info_attribute = render_properties[attribute_name]
		var deserialized_attribute = config_attribute
		
		# See if there is a non-trivial deserialization function
		var deserialized = _lookup_deserialization(
			config_attribute, render_info_attribute, layer_resource, abs_path)
		if deserialized != null: 
			deserialized_attribute = deserialized
		
		layer_resource.render_info.set(attribute_name, deserialized_attribute)
	
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


static func _lookup_deserialization(config_attribute, render_info_attribute, layer_res, abs_path):
	# Check if it is a class name (e.g. GeoRasterLayer or GeoFeatureLayer do have as they are
	# gdnative objects)
	if render_info_attribute["class_name"] in deserialization_lookup:
		var deserializer_func = deserialization_lookup[render_info_attribute["class_name"]]
		return deserializer_func.call(config_attribute, abs_path)
	
	# If the to be configured attribute in the render_info is not an object, deserialization
	# needs to be trivial, otherwise it needs to be wrapped
	if render_info_attribute.type != TYPE_OBJECT:
		return
	if not layer_res.render_info.get(render_info_attribute.name) is SerializationWrapper:
		return
	
	# The lookup the class name in the lookup dictionary
	var lookup_string = layer_res.render_info.get(render_info_attribute.name).call("get_class_name")
	if lookup_string in deserialization_lookup:
		var deserializer_func = deserialization_lookup[lookup_string]
		return deserializer_func.call(config_attribute, abs_path)


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
