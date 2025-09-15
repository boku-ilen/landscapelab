extends GeoGameObject
class_name GameObjectCluster


var game_objects_in_cluster = [GeoGameObject]
var cluster_size

signal cluster_size_changed


func change_cluster_size(new_cluster_size):
	cluster_size = new_cluster_size
	cluster_size_changed.emit(new_cluster_size)


func set_attribute(attribute_name, value, is_manual_change := false):
	super.set_attribute(attribute_name, value, is_manual_change)
	
	for game_object in game_objects_in_cluster:
		# Regardless of whether this attribute was set manually in the cluster object, the
		# individual objects are receiving the change automatically, so the 3rd parameter is false
		game_object.set_attribute(attribute_name, value, false)


func set_game_objects_in_cluster(new_game_objects_in_cluster):
	game_objects_in_cluster = new_game_objects_in_cluster
	
	# Initialize with attributes
	var attributes = get_attributes()
	for attribute_name in attributes.keys():
		for game_object in game_objects_in_cluster:
			# Note that the third parameter `false` specifies that this change was not made
			#  manually, but automatically
			game_object.set_attribute(attribute_name, attributes[attribute_name], false)
