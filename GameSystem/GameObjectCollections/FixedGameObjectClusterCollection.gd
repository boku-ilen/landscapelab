extends GameObjectCollection
class_name FixedGameObjectClusterCollection

#
# A collection of clusters of GameObjects at pre-defined locations.
#

var feature_layer: GeoFeatureLayer
var instance_goc: GameObjectCollection

var cluster_centroid_layer: GeoFeatureLayer
var cluster_points_layer: GeoFeatureLayer

var initial_search_radius := 100.0
var max_search_radius := 2000.0

var cluster_feature_instances := {}
var location_feature_instances := {}

signal game_object_added(new_game_object)
signal game_object_removed(removed_game_object)


func _init(initial_name, initial_feature_layer, initial_instance_goc,
		initial_cluster_centroid_layer, initial_cluster_points_layer):
	super._init(initial_name)
	
	feature_layer = initial_feature_layer
	instance_goc = initial_instance_goc
	
	cluster_centroid_layer = initial_cluster_centroid_layer
	cluster_points_layer = initial_cluster_points_layer
	
	# Register all existing features
	for feature in feature_layer.get_all_features():
		_add_game_object(feature)
	
	# Register future features automatically
	feature_layer.feature_added.connect(_add_game_object)
	feature_layer.feature_removed.connect(_remove_game_object)


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
	
	feature.feature_changed.connect(_on_feature_changed.bind(feature))
	
	game_object_added.emit(game_object_for_feature)
	changed.emit()


func _on_feature_changed(feature):
	# Remove previous
	if feature.get_id() in location_feature_instances:
		for feature_instance in location_feature_instances[feature.get_id()]:
			instance_goc.feature_layer.remove_feature(feature_instance)
	
	# Activate locations
	var feature_position = feature.get_vector3()
	
	var chosen_centroids
	var chosen_centroid
	
	# Repeat search until we found a cluster centroid
	var current_search_radius = initial_search_radius
	
	while current_search_radius < max_search_radius:
		var centroid_features = cluster_centroid_layer.get_features_near_position(
			feature_position.x,
			-feature_position.z,
			current_search_radius,
			1000
		)
		
		if centroid_features.size() > 0:
			chosen_centroids = centroid_features
			break
		else:
			current_search_radius *= 2.0
	
	if chosen_centroids:
		chosen_centroids.sort_custom(func(a, b):
			return a.get_vector3().distance_to(feature_position) < \
					b.get_vector3().distance_to(feature_position)
		)
		
		chosen_centroid = chosen_centroids[0]
	
		cluster_feature_instances[feature.get_id()] = []
		
		# Activate all points within this cluster
		var points_to_activate = cluster_points_layer.get_features_by_attribute_filter("CLUSTER_ID = %s" % [chosen_centroid.get_attribute("CLUSTER_ID")])
		
		for point_feature in points_to_activate:
			var new_location_feature = instance_goc.feature_layer.create_feature()
			new_location_feature.set_vector3(point_feature.get_vector3())
			
			cluster_feature_instances[feature.get_id()].append(new_location_feature)
		
		changed.emit()


func _remove_game_object(feature):
	# TODO: do this more elegantly without iterating over everything
	# find corresponding object
	var corresponding_game_object
	
	for game_object in game_objects.values():
		if game_object.geo_feature.get_id() == feature.get_id():
			corresponding_game_object = game_object
	
	if corresponding_game_object:
		# Remove cluster instances if there are any
		if feature.get_id() in cluster_feature_instances:
			for feature_instance in cluster_feature_instances[feature.get_id()]:
				instance_goc.feature_layer.remove_feature(feature_instance)
		
		GameSystem.apply_game_object_removal(name, corresponding_game_object.id)
		
		game_object_removed.emit(corresponding_game_object)
		changed.emit()
