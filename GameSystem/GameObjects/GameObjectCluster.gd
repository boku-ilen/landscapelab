extends GeoGameObject
class_name GameObjectCluster


var game_objects_in_cluster = []


func set_attribute(attribute_name, value):
	super.set_attribute(attribute_name, value)
	
	for game_object in game_objects_in_cluster:
		game_object.set_attribute(attribute_name, value)
