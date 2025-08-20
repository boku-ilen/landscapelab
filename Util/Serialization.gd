extends Object
class_name Serialization


static func deserialize(attributes: Dictionary, object: RefCounted, absolute_path: String, look_up_funtion := Callable(func(): return)):
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
		
		# See if there is a non-trivial deserialization function
		if look_up_funtion != Callable(func(): return):
			var deserialized = look_up_funtion.call(
				config_attribute, attribute, object, absolute_path)
			if deserialized != null: 
				deserialized_attribute = deserialized
		
		if attribute_name in object:
			object.set(attribute_name, deserialized_attribute)
	
	return object
