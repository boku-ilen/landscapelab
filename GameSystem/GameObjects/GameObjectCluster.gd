extends GeoGameObject
class_name GameObjectCluster


var game_objects_in_cluster = []

signal cluster_size_changed


func change_cluster_size(new_cluster_size):
	cluster_size_changed.emit(new_cluster_size)


func set_attribute(attribute_name, value):
	super.set_attribute(attribute_name, value)
	
	for game_object in game_objects_in_cluster:
		game_object.set_attribute(attribute_name, value)
