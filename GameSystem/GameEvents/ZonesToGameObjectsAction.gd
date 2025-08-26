extends EventAction
class_name ZonesToGameObjectsAction

#
# A collection of clusters of GameObjects at pre-defined locations.
#

var feature_layer: GeoFeatureLayer
var activation_layer: GeoFeatureLayer

var good_zone_goc: GeoGameObjectCollection
var bad_zone_goc: GeoGameObjectCollection

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
		initial_activation_layer,
		initial_good_zone_goc,
		initial_bad_zone_goc,
		initial_target_score_name
	):
	
	feature_layer = initial_feature_layer
	activation_layer = initial_activation_layer
	good_zone_goc = initial_good_zone_goc
	bad_zone_goc = initial_bad_zone_goc
	target_score_name = initial_target_score_name


func apply(_game_mode: GameMode):
	# Delete all previous features
	# FIXME: Maybe don't do that and try to preserve changes made there, in case the game mode is
	#  switched back and forth
	for feature in feature_layer.get_all_features():
		feature_layer.remove_feature(feature)
	
	var good_zone_features = good_zone_goc.feature_layer.get_all_features()
	var bad_zone_features = bad_zone_goc.feature_layer.get_all_features()
	
	var activation_points = activation_layer.get_all_features()
	
	var cluster_and_id_and_score = []
	
	for activation_point in activation_points:
		var id = activation_point.get_attribute("CLUSTER_ID")
		var activation_point_center = activation_point.get_vector3()
		var activation_point_radius = float(activation_point.get_attribute("radius"))
		
		var score := 0.0
		
		for good_zone in good_zone_features:
			var zone_center = good_zone.get_vector3()
			var zone_radius = float(good_zone.get_attribute("radius"))
			
			var distance = activation_point_center.distance_to(zone_center)
			
			# If the object is somewhat close, add a fixed value of 2.0 as well as a value between
			#  0.0 and 1.0 depending on the distance, so that we prefer clusters closer to the
			#  zone centers
			if distance < zone_radius:
				score += 1.0 + inverse_lerp(zone_radius + activation_point_radius, 0.0, distance)
			elif distance < zone_radius + activation_point_radius:
				score += inverse_lerp(zone_radius + activation_point_radius, zone_radius, distance)
		
		for bad_zone in bad_zone_features:
			var zone_center = bad_zone.get_vector3()
			var zone_radius = float(bad_zone.get_attribute("radius"))
			
			var distance = activation_point_center.distance_to(zone_center)
			
			# If the object is somewhat close, add a fixed value of 2.0 as well as a value between
			#  0.0 and 1.0 depending on the distance, so that we prefer clusters closer to the
			#  zone centers
			if distance < zone_radius:
				score -= 1.0 + inverse_lerp(zone_radius + activation_point_radius, 0.0, distance)
			elif distance < zone_radius + activation_point_radius:
				score -= inverse_lerp(zone_radius + activation_point_radius, zone_radius, distance)
		
		cluster_and_id_and_score.append([activation_point, id, score])
	
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
