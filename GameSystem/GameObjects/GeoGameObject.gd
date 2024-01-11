extends GameObject
class_name GeoGameObject


var geo_feature


func _init(initial_id: int,initial_collection,initial_geo_feature):
	super._init(initial_id, initial_collection)
	
	geo_feature = initial_geo_feature


func get_attribute(attribute_name: String):
	if not collection.attributes.has(attribute_name):
		logger.error("Invalid attribute with name {n}".format({"n": attribute_name}))
		return null
	
	return collection.attributes[attribute_name].get_value(self)


func set_attribute(attribute_name, value):
	if not collection.attributes.has(attribute_name):
		logger.error("Invalid attribute with name {n}".format({"n": attribute_name}))
	else:
		collection.attributes[attribute_name].set_value(self, value)


func set_position(new_position: Vector3):
	geo_feature.set_vector3(new_position)


func get_position():
	return geo_feature.get_vector3()
