extends Object
class_name LayerCompositionSerializer

# RenderInfo class
const render_info_to_serialized_str := {
	
}

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
			# E.g. ./LL.gpkg:ortho?w
			# => ["./LL.gpkg", "ortho?w"]
			var path_layer_split = attributes[attribute_name].split(":")
			# => ["ortho", "w"]
			var layer_access_split = path_layer_split[1].split("?")
			var abs_file_name = LLFileAccess.get_rel_or_abs_path(abs_path, path_layer_split[0])
			var layer_name = layer_access_split[0]
			var write_access = true if layer_access_split.size() > 1 and layer_access_split[1] == "w" else false
			
			var db = Geodot.get_dataset(abs_file_name, write_access)
			
			if render_attribute["class_name"] == "GeoRasterLayer":
				attribute = db.get_raster_layer(layer_name)
			elif render_attribute["class_name"] == "GeoFeatureLayer":
				attribute = db.get_feature_layer(layer_name)
		
		layer_composition.render_info.set(attribute_name, attribute)
	
	return layer_composition


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
