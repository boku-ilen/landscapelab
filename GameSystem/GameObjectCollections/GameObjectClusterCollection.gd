extends GameObjectCollection
class_name GameObjectClusterCollection

#
# A collection of clusters of GameObjects at pre-defined locations.
#

var attributes = {}
var feature_layer
var location_layer
var instance_goc

var cluster_size := 8
var min_cluster_size := 1
var max_cluster_size := 20
var initial_search_radius := 200.0
var max_search_radius := 5000.0
var location_feature_instances := {}
var used_locations := {}

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
	
	var location_features = []
	var current_search_radius = initial_search_radius
	
	# Repeat search until we found enough features or the radius gets too big
	while current_search_radius < max_search_radius:
		location_features = location_layer.get_features_near_position(
			feature_position.x,
			-feature_position.z,
			current_search_radius,
			1000
		)
		
		if location_features.size() >= cluster_size:
			break
		else:
			current_search_radius *= 2.0
	
	location_features.sort_custom(func(a, b):
		return a.get_vector3().distance_to(feature_position) < \
				b.get_vector3().distance_to(feature_position)
	)
	
	# Resize to a maximum of cluster_size
	location_features.resize(min(cluster_size, location_features.size()))
	var instances = []
	
	for location_feature in location_features:
		var location = location_feature.get_vector3()
		
		# Is there already an instance here?
		if location in used_locations: continue
		
		var new_location_feature = instance_goc.feature_layer.create_feature()
		new_location_feature.set_vector3(location)
		used_locations[location] = true
		instances.append(new_location_feature)
	
	location_feature_instances[feature.get_id()] = instances
	
	emit_signal("changed")


func _remove_game_object(feature):
	# TODO: do this more elegantly without iterating over everything
	# find corresponding object
	var corresponding_game_object
	
	for game_object in game_objects.values():
		if game_object.geo_feature.get_id() == feature.get_id():
			corresponding_game_object = game_object
	
	if corresponding_game_object:
		# Remove cluster instances
		for feature_instance in location_feature_instances[feature.get_id()]:
			used_locations.erase(feature_instance.get_vector3())
			instance_goc.feature_layer.remove_feature(feature_instance)
		
		GameSystem.apply_game_object_removal(name, corresponding_game_object.id)
		
		emit_signal("game_object_removed", corresponding_game_object)
		emit_signal("changed")


func add_attribute_mapping(attribute):
	attributes[attribute.name] = attribute
	emit_signal("changed")

