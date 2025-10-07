extends Object
class_name Serialization

static var empty_callable := Callable(func(): return)
static func deserialize(attributes: Dictionary, object: Object, absolute_path: String, look_up_function := empty_callable):
	var named_properties = {}
	for property in object.get_property_list():
		named_properties[property["name"]] = property
	
	for attribute_name in attributes:
		if not attribute_name in named_properties:
			logger.warn("An attribute \"%s\" was found for \"%s\" in the config file, 
				but it is not a valid property of that resource" % [attribute_name, object])
			continue
		
		var config_attribute = attributes[attribute_name]
		var attribute = named_properties[attribute_name]
		var deserialized_attribute = config_attribute
		
		if look_up_function != empty_callable:
			if attribute.type == TYPE_ARRAY:
				var non_trivial_array = []
				for i in deserialized_attribute.size():
					non_trivial_array.append(non_trivial_deserialize(look_up_function, attribute, config_attribute[i], object, absolute_path))
				deserialized_attribute = Array(non_trivial_array, TYPE_OBJECT, attribute.hint_string, null)
			else:
				deserialized_attribute = non_trivial_deserialize(look_up_function, attribute, config_attribute, object, absolute_path)
		
		if attribute_name in object:
			object.set(attribute_name, deserialized_attribute)
	
	return object


static func non_trivial_deserialize(look_up_function, attribute, config_attribute, object, absolute_path): 
	# See if there is a non-trivial deserialization function
	var deserialized = look_up_function.call(
		config_attribute, attribute, object, absolute_path)
	if deserialized != null: 
		return deserialized
	
	return config_attribute
