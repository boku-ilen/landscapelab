extends GameObjectCollection
class_name GameObjectClusterCollection

#
# A collection of clusters of GameObjects at pre-defined locations.
#

var attributes = {}
var feature_layer
var location_layer
var instance_goc

var cluster_size = 8
var search_radius = 4000.0
var game_object_instances = {}

signal game_object_added(new_game_object)
signal game_object_removed(removed_game_object)


func _init(initial_name, initial_feature_layer, initial_location_layer, initial_instance_goc):
	super._init(initial_name)
	
	feature_layer = initial_feature_layer
	location_layer = initial_location_layer
	instance_goc = initial_instance_goc
	
	# Register all existing features
	for feature in feature_layer.get_all_features():
		_add_game_object(feature)
	
	# Register future features automatically
	feature_layer.connect("feature_added",Callable(self,"_add_game_object"))
	feature_layer.connect("feature_removed",Callable(self,"_remove_game_object"))


func remove_nearby_game_objects(position, radius):
	var features = feature_layer.get_features_near_position(
		position.x,
		position.z,
		radius,
		10000
	)
	
	for feature in features:
		feature_layer.remove_feature(feature)


func _add_game_object(feature):
	var game_object_for_feature = GameSystem.create_game_object_for_geo_feature(feature, self)
	game_objects[game_object_for_feature.id] = game_object_for_feature
	
	feature.connect("feature_changed",Callable(self,"_on_feature_changed").bind(feature))
	
	emit_signal("game_object_added", game_object_for_feature)
	emit_signal("changed")


func _on_feature_changed(feature):
	# Activate locations
	var feature_position = feature.get_vector3()
	
	var location_features = location_layer.get_features_near_position(
		feature_position.x,
		-feature_position.z,
		search_radius,
		1000
	)
	
	location_features.sort_custom(func(a, b):
		return a.get_vector3().distance_to(feature_position) < \
				b.get_vector3().distance_to(feature_position)
	)
	
	location_features.resize(cluster_size)
	
	for location_feature in location_features:
		var location = location_feature.get_vector3()
		var new_location_feature = instance_goc.feature_layer.create_feature()
		new_location_feature.set_vector3(location)
		#var game_object_instance = GameSystem.create_game_object_for_geo_feature(location_feature, instance_goc)
		#game_object_instances[game_object_instance.id] = game_object_instance
	
	emit_signal("changed")


func _remove_game_object(feature):
	# TODO: do this more elegantly without iterating over everything
	# find corresponding object
	var corresponding_game_object
	
	for game_object in game_objects.values():
		if game_object.geo_feature.get_id() == feature.get_id():
			corresponding_game_object = game_object
	
	if corresponding_game_object:
		# TODO: Remove cluster instances
		
		GameSystem.apply_game_object_removal(name, corresponding_game_object.id)
		
		emit_signal("game_object_removed", corresponding_game_object)
		emit_signal("changed")


func add_attribute_mapping(attribute):
	attributes[attribute.name] = attribute
	emit_signal("changed")

