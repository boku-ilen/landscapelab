extends Object
class_name LayerCompositionSerializer

# RenderInfo class
const render_info_to_serialized_str := {
	
}


static func get_geolayer_from_path(abs_path: String, attribute_name: String, cls_name: String):
	# Split data into {LL_xy.gpkg, layer_name, write_access}
	var splits = LLFileAccess.split_dataset_string(abs_path, attribute_name)
	
	if cls_name == "GeoRasterLayer":
		return LLFileAccess.get_layer_from_splits(splits, true)
	elif cls_name == "GeoFeatureLayer":
		return LLFileAccess.get_layer_from_splits(splits, false)
	
	return null


static func deserialize(
		abs_path: String, composition_name: String, 
		type: String, attributes: Dictionary, 
		layer_composition: LayerComposition = LayerComposition.new()):
	
	layer_composition.name = composition_name
	layer_composition.render_info = layer_composition.RENDER_INFOS[type].new()
	
	var render_properties = {}
	for property in layer_composition.render_info.get_property_list():
		render_properties[property["name"]] = property
	
	for attribute_name in attributes:
		var attribute = attributes[attribute_name]
		var render_attribute = render_properties[attribute_name]

		if render_attribute["class_name"] in ["GeoRasterLayer", "GeoFeatureLayer"]:
			attribute = get_geolayer_from_path(abs_path, attribute, render_attribute["class_name"])
		
		layer_composition.render_info.set(attribute_name, attribute)
	
	return layer_composition


static func get_feature_layer_from_string(path_string, abs_path):
	var path_layer_split = path_string.split(":")
	# => ["ortho", "w"]
	var layer_access_split = path_layer_split[1].split("?")
	var abs_file_name = LLFileAccess.get_rel_or_abs_path(abs_path, path_layer_split[0])
	var layer_name = layer_access_split[0]
	var write_access = true if layer_access_split.size() > 1 and layer_access_split[1] == "w" else false
	
	var db = Geodot.get_dataset(abs_file_name, write_access)
	
	return db.get_feature_layer(layer_name)


static func serialize(layer_composition: LayerComposition):
	# Create list of basic Object properties so we can ignore those later
	var base_property_names = []
	var base_render_info = LayerComposition.RenderInfo.new()
	for property in base_render_info.get_property_list():
		base_property_names.append(property["name"])
		
	var attributes = {}
	for property in layer_composition.render_info.get_property_list():
		# Ignore basic Object properties
		if property["name"] in base_property_names: continue
		var type = property["type"]
		if property["type"] == TYPE_OBJECT:
			type = property["class_name"]
		
		var property_var = layer_composition.render_info.get(property["name"])
		var serialized
		
		match type:
			"GeoRasterLayer":
				serialized = "{}:{}?{}".format(
					[property_var.get_dataset().get_file_info()["path"],
					property_var.get_file_info()["name"],
					"w" if property_var.get_dataset().has_write_access() else "r"], "{}")
			"GeoFeatureLayer": 
				serialized = "{}:{}?{}".format(
					[property_var.get_file_info()["path"],
					property_var.get_file_info()["name"],
					"w" if property_var.get_dataset().has_write_access() else "r"], "{}")
			"Color": 
				serialized = str(property_var)
			_:
				serialized = property_var
	
		attributes[property["name"]] = serialized 
	
	var serialized = {
		layer_composition.name: {
			"type": layer_composition.render_info.get_class_name(),
			"attributes": attributes
		}
	}
	
	return serialized
