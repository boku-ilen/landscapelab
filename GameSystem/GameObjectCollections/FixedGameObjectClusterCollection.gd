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

var feature_id_to_game_object = {}
var current_new_game_objects = []
var feature_id_to_cluster_id = {}

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
	
	# Check whether necessary attributes exist and warn if not
	if not feature_layer.has_attribute("modified"):
		logger.error("""
			Feature layer in GameObjectCollection %s does not have `modified` attribute, this will
			make saving and loading inconsistent!
		""" % [initial_name])
	
	if not instance_goc.feature_layer.has_attribute("modified"):
		logger.error("""
			Instance feature layer in GameObjectCollection %s does not have `modified` attribute, this will
			make saving and loading inconsistent!
		""" % [initial_name])
	
	if not cluster_centroid_layer.has_attribute("CLUSTER_ID"):
		logger.error("""
			Cluster centroid layer in GameObjectCollection %s does not have `CLUSTER_ID` attribute,
			it cannot activate locations without it!
		""" % [initial_name])
	
	if not cluster_points_layer.has_attribute("CLUSTER_ID"):
		logger.error("""
			Cluster points layer in GameObjectCollection %s does not have `CLUSTER_ID` attribute,
			it cannot activate locations without it!
		""" % [initial_name])
	
	if not instance_goc.feature_layer.has_attribute("origin"):
		logger.error("""
			Instance feature layer in GameObjectCollection %s does not have `origin` attribute,
			this will cause the mapping of clusters to instances to be broken!
		""" % [initial_name])
	
	if not cluster_points_layer.has_attribute("activated"):
		logger.error("""
			Cluster points layer in GameObjectCollection %s does not have `activated` attribute,
			this will allow duplicate cluster activations!
		""" % [initial_name])
		
		


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
	
	feature.feature_changed.connect(_on_feature_changed.bind(feature))
	
	game_object_added.emit(game_object_for_feature)
	changed.emit()


func _on_feature_changed(feature):
	# Get the closest cluster corresponding to this feature
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
	
	if not chosen_centroids: return
	
	chosen_centroids.sort_custom(func(a, b):
		return a.get_vector3().distance_to(feature_position) < \
				b.get_vector3().distance_to(feature_position)
	)
	
	chosen_centroid = chosen_centroids[0]
	
	# Now that we have a "chosen_centroid", check whether we have previous features for it
	var cluster_id = chosen_centroid.get_attribute("CLUSTER_ID")
	
	feature_id_to_cluster_id[feature.get_id()] = cluster_id
	
	# Remove unmodified existing features, but remember their locations to recreate them later
	# We do this to make attribute changes propagate down
	var existing_locations = []
	var existing_features = instance_goc.feature_layer\
			.get_features_by_attribute_filter("origin = '%s'" % [cluster_id])
	
	for existing_feature in existing_features:
		if not str_to_var(existing_feature.get_attribute("modified")):
			existing_locations.append(existing_feature.get_vector3())
			instance_goc.feature_layer.remove_feature(existing_feature)
	
	# React to new game objects so that we know about GameObjects created
	# as a reaction to `instance_goc.feature_layer.create_feature()`
	current_new_game_objects.clear()
	instance_goc.game_object_added.connect(add_current_new_game_object)
	
	# Recreate removed unmodified existing features
	for existing_location in existing_locations:
		var new_location_feature = instance_goc.feature_layer.create_feature()
		new_location_feature.set_vector3(existing_location)
		new_location_feature.set_attribute("origin", str(cluster_id))
	
	# Activate all unactivated points within this cluster
	# (This is likely only ever relevant for when this function is first called, since later, all
	#  are activated)
	var points_to_activate = cluster_points_layer.get_features_by_attribute_filter(
		"CLUSTER_ID = %s" % [cluster_id]
	)
	
	for point_feature in points_to_activate:
		var activated = point_feature.get_attribute("activated")
		if str_to_var(activated): continue
		
		var new_location_feature = instance_goc.feature_layer.create_feature()
		new_location_feature.set_vector3(point_feature.get_vector3())
		new_location_feature.set_attribute("origin", str(cluster_id))
		
		# If an individual location feature gets "modified" set to "true", we also want this to
		#  propagate to the cluster feature. The reason is this: if this cluster was automatically
		#  placed by a ZonesToGameObjectsAction, it should be considered "modified" (and therefore
		#  persisted) even if it is not itself modified, but if a feature of it is modified, since
		#  that also means we don't want to delete the cluster (and with it the modified features).
		new_location_feature.feature_changed.connect(
			_on_location_feature_changed.bind(new_location_feature, feature))
		
		point_feature.set_attribute("activated", "1")
	
	instance_goc.game_object_added.disconnect(add_current_new_game_object)
	
	# Let this game object know its child game objects so it can e.g. set their attributes
	feature_id_to_game_object[feature.get_id()].set_game_objects_in_cluster(current_new_game_objects)
	
	changed.emit()


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
		# Have we activated a cluster for this feature?
		if feature.get_id() in feature_id_to_cluster_id:
			var cluster_id = feature_id_to_cluster_id[feature.get_id()]
			
			# Get the features which have this cluster set as origin
			var relevant_features = instance_goc.feature_layer\
					.get_features_by_attribute_filter("origin = '%s'" % [cluster_id])
			
			# Remove them
			for feature_instance in relevant_features:
				instance_goc.feature_layer.remove_feature(feature_instance)
			
			# Set the underlying activation points to unactivated
			var points_to_set_inactive = cluster_points_layer.get_features_by_attribute_filter(
				"CLUSTER_ID = %s" % [cluster_id]
			)
			
			for point_feature in points_to_set_inactive:
				point_feature.set_attribute("activated", "0")
		
		GameSystem.apply_game_object_removal(name, corresponding_game_object.id)
		
		game_object_removed.emit(corresponding_game_object)
	
		changed.emit()


func _on_location_feature_changed(feature, cluster_feature):
	if feature.get_attribute("modified") == "1":
		cluster_feature.set_attribute("modified", "1")
