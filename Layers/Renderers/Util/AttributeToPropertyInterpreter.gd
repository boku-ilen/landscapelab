extends Node
class_name AttributeToPropertyInterpreter


static func get_properties_for_feature(feature: GeoFeature, attributes_to_properties: Dictionary):
	var property_dict = {}
	var property_priorities = {}
	
	# Apply initial default values if defined
	if "_default" in attributes_to_properties:
		property_dict = attributes_to_properties["_default"].duplicate(true)
	
	for attribute_name in attributes_to_properties.keys():
		if attribute_name == "_default": continue  # Ignore the default setting
		
		var values_to_properties = attributes_to_properties[attribute_name]
		var value_here = feature.get_attribute(attribute_name)
		
		var properties
		
		if value_here in values_to_properties:
			# Top priority: this value is defined explicitly
			properties = values_to_properties[value_here]
		elif "_default" in values_to_properties:
			# Lower priority: this attribute has a default class
			properties = values_to_properties["_default"]
		
		if properties:
			for property_name in properties.keys():
				var property = properties[property_name]
				
				if property is Dictionary:
					# This property has extra information, check that
					if "priority" in property:
						# Override only if priority is higher (or not yet set)
						if (not property_name in property_priorities) \
								or (property_priorities[property_name] < property["priority"]):
							property_dict[property_name] = property["value"]
				else:
					# Normal property, set directly
					# Give a warning if this overrides in an undefined way
					if property_name in property_dict:
						logger.warn("Property %s for attribute %s with value %s overrides the\
						existing value %s without defining a priority, this is undefined!"
						% [property_name, attribute_name, str(property), str(property_dict[property_name])])
					property_dict[property_name] = property
					property_priorities[property_name] = 0
	
	return property_dict


# The old way of defining - kept for backwards compatibility (for now)
static func get_mesh_dict_key_from_feature(feature: GeoFeature, selector_attribute_name: String, meshes: Dictionary):
	var attribute_name = selector_attribute_name
	var possible_meshes = meshes.keys()
	var mesh_key = feature.get_attribute(attribute_name) if attribute_name != null else "default"
	mesh_key = mesh_key if mesh_key != "" else "default"
	mesh_key = possible_meshes[0] if not mesh_key in possible_meshes else mesh_key
	
	var mesh_key_dict = meshes[mesh_key].duplicate(true)
	
	return mesh_key_dict
