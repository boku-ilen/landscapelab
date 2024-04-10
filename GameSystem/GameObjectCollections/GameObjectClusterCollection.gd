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
var max_cluster_size := 40
var initial_search_radius := 200.0
var max_search_radius := 5000.0
var location_feature_instances := {}
var used_locations := {}

var current_new_game_objects = []
var feature_id_to_game_object = {}

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
	var game_object_for_feature = GameSystem.create_game_object_for_geo_feature(GameObjectCluster, feature, self)
	game_objects[game_object_for_feature.id] = game_object_for_feature
	feature_id_to_game_object[feature.get_id()] = game_object_for_feature
	
	feature.connect("feature_changed",Callable(self,"_on_feature_changed").bind(feature))
	game_object_for_feature.cluster_size_changed.connect(func(new_cluster_size):
		cluster_size = new_cluster_size
		_on_feature_changed(feature)
	)
	
	emit_signal("game_object_added", game_object_for_feature)
	emit_signal("changed")


func _on_feature_changed(feature):
	# Remove previous
	if feature.get_id() in location_feature_instances:
		var corresponding_game_object
		
		for game_object in game_objects.values():
			if game_object.geo_feature.get_id() == feature.get_id():
				corresponding_game_object = game_object
		
		for feature_instance in location_feature_instances[feature.get_id()]:
			used_locations.erase(feature_instance.get_vector3())
			instance_goc.feature_layer.remove_feature(feature_instance)
	
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
	
	# React to new game objects so that we know about GameObjects created
	# as a reaction to `instance_goc.feature_layer.create_feature()`
	current_new_game_objects.clear()
	instance_goc.game_object_added.connect(add_current_new_game_object)
	
	for location_feature in location_features:
		var location = location_feature.get_vector3()
		
		# Is there already an instance here?
		if location in used_locations: continue
		
		var new_location_feature = instance_goc.feature_layer.create_feature()
		new_location_feature.set_vector3(location)
		used_locations[location] = true
		instances.append(new_location_feature)
	
	# Remember feature instances so we can remove them later
	location_feature_instances[feature.get_id()] = instances
	
	# Let this game object know its child game objects so it can e.g. set their attributes
	feature_id_to_game_object[feature.get_id()].game_objects_in_cluster = current_new_game_objects
	
	instance_goc.game_object_added.disconnect(add_current_new_game_object)
	
	emit_signal("changed")


func add_current_new_game_object(new_game_object):
	current_new_game_objects.append(new_game_object)


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

