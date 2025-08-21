extends GameObjectCollection
class_name GameObjectClusterFromZonesCollection

#
# A collection of clusters of GameObjects at pre-defined locations.
#

var feature_layer: GeoFeatureLayer
var cluster_centroid_layer: GeoFeatureLayer
var cluster_points_layer: GeoFeatureLayer

var good_zone_goc: GeoGameObjectCollection
var bad_zone_goc: GeoGameObjectCollection
var insert_goc: GeoGameObjectCollection

# FIXME: We'd want to use the GameScore object directly, but since GOCs are deserialized before
#  scores, it doesn't exist when this object is being created. We'd need a way to lazy initialize
var target_score_name: String

var cluster_feature_instances := {}

var min_cluster_size := 1
var max_cluster_size := 40
var default_cluster_size := 10
var initial_search_radius := 200.0
var max_search_radius := 5000.0
var location_feature_instances := {}
var used_locations := {}

var current_new_game_objects = []
var feature_id_to_game_object = {}

signal game_object_added(new_game_object)
signal game_object_removed(removed_game_object)


func _init(
		initial_name,
		initial_feature_layer,
		initial_cluster_centroid_layer,
		initial_cluster_points_layer,
		initial_good_zone_goc,
		initial_bad_zone_goc,
		initial_insert_goc,
		initial_target_score_name
	):
	super._init(initial_name)
	
	feature_layer = initial_feature_layer
	cluster_centroid_layer = initial_cluster_centroid_layer
	cluster_points_layer = initial_cluster_points_layer
	good_zone_goc = initial_good_zone_goc
	bad_zone_goc = initial_bad_zone_goc
	insert_goc = initial_insert_goc
	target_score_name = initial_target_score_name
	
	## Register all existing features
	#for feature in feature_layer.get_all_features():
		#_add_game_object(feature)
	
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


func activate():
	# Delete all previous features
	for feature in feature_layer.get_all_features():
		feature_layer.remove_feature(feature)
	
	var good_zone_features = good_zone_goc.feature_layer.get_all_features()
	var bad_zone_features = bad_zone_goc.feature_layer.get_all_features()
	
	var clusters = cluster_centroid_layer.get_all_features()
	
	var cluster_and_id_and_score = []
	
	for cluster in clusters:
		var id = cluster.get_attribute("CLUSTER_ID")
		var cluster_center = cluster.get_vector3()
		var cluster_radius = float(cluster.get_attribute("radius"))
		
		var score := 0.0
		
		for good_zone in good_zone_features:
			var zone_center = good_zone.get_vector3()
			var zone_radius = float(good_zone.get_attribute("radius"))
			
			var distance = cluster_center.distance_to(zone_center)
			
			# If the object is somewhat close, add a fixed value of 2.0 as well as a value between
			#  0.0 and 1.0 depending on the distance, so that we prefer clusters closer to the
			#  zone centers
			if distance < zone_radius:
				score += 1.0 + inverse_lerp(zone_radius + cluster_radius, 0.0, distance)
			elif distance < zone_radius + cluster_radius:
				score += inverse_lerp(zone_radius + cluster_radius, zone_radius, distance)
		
		for bad_zone in bad_zone_features:
			var zone_center = bad_zone.get_vector3()
			var zone_radius = float(bad_zone.get_attribute("radius"))
			
			var distance = cluster_center.distance_to(zone_center)
			
			# If the object is somewhat close, add a fixed value of 2.0 as well as a value between
			#  0.0 and 1.0 depending on the distance, so that we prefer clusters closer to the
			#  zone centers
			if distance < zone_radius:
				score -= 1.0 + inverse_lerp(zone_radius + cluster_radius, 0.0, distance)
			elif distance < zone_radius + cluster_radius:
				score -= inverse_lerp(zone_radius + cluster_radius, zone_radius, distance)
		
		cluster_and_id_and_score.append([cluster, id, score])
	
	cluster_and_id_and_score.sort_custom(func(a, b): return a[2] > b[2])
	
	while true:
		# Exit condition: score reached
		GameSystem.current_game_mode.game_scores[target_score_name].recalculate_score()
		if GameSystem.current_game_mode.game_scores[target_score_name].is_target_reached(): break
		
		# Exit condition: all clusters activated
		if cluster_and_id_and_score.size() <= 0: break
		
		var cluster = cluster_and_id_and_score.pop_front()
		
		# Exit condition: no good clusters left
		if cluster[2] <= 0: break
		
		# Activate this cluster
		var new_cluster_feature = feature_layer.create_feature()
		new_cluster_feature.set_vector3(cluster[0].get_vector3())
		
		cluster_feature_instances[new_cluster_feature.get_id()] = []
		
		# Activate all points within this cluster
		var points_to_activate = cluster_points_layer.get_features_by_attribute_filter("CLUSTER_ID = %s" % [cluster[1]])
		
		for point_feature in points_to_activate:
			var new_location_feature = insert_goc.feature_layer.create_feature()
			new_location_feature.set_vector3(point_feature.get_vector3())
			
			cluster_feature_instances[new_cluster_feature.get_id()].append(new_location_feature)


func _add_game_object(feature):
	var game_object_for_feature = GameSystem.create_game_object_for_geo_feature(GeoGameObject, feature, self)
	game_objects[game_object_for_feature.id] = game_object_for_feature
	feature_id_to_game_object[feature.get_id()] = game_object_for_feature
	
	#feature.connect("feature_changed",Callable(self,"_on_feature_changed").bind(feature, game_object_for_feature))
	
	emit_signal("game_object_added", game_object_for_feature)
	emit_signal("changed")

#
#func _on_feature_changed(feature, game_object_for_feature):
	#var cluster_size = game_object_for_feature.cluster_size
	#
	## Remove previous
	#if feature.get_id() in location_feature_instances:
		#var corresponding_game_object
		#
		#for game_object in game_objects.values():
			#if game_object.geo_feature.get_id() == feature.get_id():
				#corresponding_game_object = game_object
		#
		#for feature_instance in location_feature_instances[feature.get_id()]:
			#used_locations.erase(feature_instance.get_vector3())
			#instance_goc.feature_layer.remove_feature(feature_instance)
	#
	## Activate locations
	#var feature_position = feature.get_vector3()
	#
	#var location_features = []
	#
	#if cluster_size == 1:
		## If the cluster size is 1, place an object exactly at this feature's location
		## But first, check the placement-allowed-map
		#location_features.append(feature)
	#else:
		## Repeat search until we found enough features or the radius gets too big
		#var current_search_radius = initial_search_radius
		#
		#while current_search_radius < max_search_radius:
			#location_features = location_layer.get_features_near_position(
				#feature_position.x,
				#-feature_position.z,
				#current_search_radius,
				#1000
			#)
			#
			#if location_features.size() >= cluster_size:
				#break
			#else:
				#current_search_radius *= 2.0
		#
		#location_features.sort_custom(func(a, b):
			#return a.get_vector3().distance_to(feature_position) < \
					#b.get_vector3().distance_to(feature_position)
		#)
		#
		## Resize to a maximum of cluster_size
		#location_features.resize(min(cluster_size, location_features.size()))
	#
	#var instances = []
	#
	## React to new game objects so that we know about GameObjects created
	## as a reaction to `instance_goc.feature_layer.create_feature()`
	#current_new_game_objects.clear()
	#instance_goc.game_object_added.connect(add_current_new_game_object)
	#
	#for location_feature in location_features:
		#var location = location_feature.get_vector3()
		#
		## Is there already an instance here?
		#if location in used_locations: continue
		#
		## FIXME: For some reason this workaround is needed to make interaction with single feature clusters work
		#if cluster_size == 1: location += Vector3.ONE
		#
		#var new_location_feature = instance_goc.feature_layer.create_feature()
		#new_location_feature.set_vector3(location)
		#used_locations[location] = true
		#instances.append(new_location_feature)
	#
	## Remember feature instances so we can remove them later
	#location_feature_instances[feature.get_id()] = instances
	#
	## Let this game object know its child game objects so it can e.g. set their attributes
	#feature_id_to_game_object[feature.get_id()].set_game_objects_in_cluster(current_new_game_objects)
	#
	#instance_goc.game_object_added.disconnect(add_current_new_game_object)
	#
	#emit_signal("changed")

#
#func add_current_new_game_object(new_game_object):
	#current_new_game_objects.append(new_game_object)
#
#
func _remove_game_object(feature):
	# TODO: do this more elegantly without iterating over everything
	# find corresponding object
	var corresponding_game_object
	
	for game_object in game_objects.values():
		if game_object.geo_feature.get_id() == feature.get_id():
			corresponding_game_object = game_object
	
	if corresponding_game_object:
		# Remove cluster instances
		for feature_instance in cluster_feature_instances[feature.get_id()]:
			insert_goc.feature_layer.remove_feature(feature_instance)
		
		GameSystem.apply_game_object_removal(name, corresponding_game_object.id)
		
		emit_signal("game_object_removed", corresponding_game_object)
		emit_signal("changed")


func add_attribute_mapping(attribute):
	attributes[attribute.name] = attribute
	emit_signal("changed")
