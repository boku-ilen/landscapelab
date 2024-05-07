extends GeoGameObject
class_name GameObjectCluster


var game_objects_in_cluster = []
var cluster_size

signal cluster_size_changed


func change_cluster_size(new_cluster_size):
	cluster_size = new_cluster_size
	cluster_size_changed.emit(new_cluster_size)


func set_attribute(attribute_name, value):
	super.set_attribute(attribute_name, value)
	
	for game_object in game_objects_in_cluster:
		game_object.set_attribute(attribute_name, value)


func set_game_objects_in_cluster(new_game_objects_in_cluster):
	game_objects_in_cluster = new_game_objects_in_cluster
	
	# Initialize with attributes
	var attributes = get_attributes()
	for attribute_name in attributes.keys():
		for game_object in game_objects_in_cluster:
			game_object.set_attribute(attribute_name, attributes[attribute_name])
