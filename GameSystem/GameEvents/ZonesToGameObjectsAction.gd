extends EventAction
class_name ZonesToGameObjectsAction

#
# Creates GameObjects based on layers of "good" and "bad" zones, trying to place them into the zones
# with the most "good" and least "bad" ratings.
# The zones need to have a "radius" attribute. An "activation_layer" containing potential points
# to check against the given zones needs to be provided.
#

var feature_layer: GeoFeatureLayer
var activation_layer: GeoFeatureLayer

var good_zone_goc: GeoGameObjectCollection
var bad_zone_goc: GeoGameObjectCollection

# FIXME: We'd want to use the GameScore object directly, but since GOCs are deserialized before
#  scores, it doesn't exist when this object is being created. We'd need a way to lazy initialize
var target_score_name: String

const FEATURE_LIMIT = 100


func _init(
		initial_name,
		initial_feature_layer,
		initial_activation_layer,
		initial_good_zone_goc,
		initial_bad_zone_goc,
		initial_target_score_name
	):
	
	name = initial_name
	feature_layer = initial_feature_layer
	activation_layer = initial_activation_layer
	good_zone_goc = initial_good_zone_goc
	bad_zone_goc = initial_bad_zone_goc
	target_score_name = initial_target_score_name
	
	# Check whether necessary attributes exist and warn if not
	if not feature_layer.has_attribute("modified"):
		logger.error("""
			Feature layer in EventAction %s does not have `modified` attribute, this will
			make saving and loading inconsistent!
		""" % [initial_name])
	
	if not activation_layer.has_attribute("radius"):
		logger.error("""
			Activation layer in EventAction %s does not have `radius` attribute, this will
			cause activation points not to work properly!
		""" % [initial_name])
	
	if not good_zone_goc.feature_layer.has_attribute("radius"):
		logger.error("""
			Good zone layer in EventAction %s does not have `radius` attribute, this will
			cause activation points not to work properly!
		""" % [initial_name])
	
	if not bad_zone_goc.feature_layer.has_attribute("radius"):
		logger.error("""
			Bad zone layer in EventAction %s does not have `radius` attribute, this will
			cause activation points not to work properly!
		""" % [initial_name])


func apply(_game_mode: GameMode):
	# Delete all previous features which have not been modified - keep features where manual changes
	#  have been made
	for feature in feature_layer.get_all_features():
		if feature.get_attribute("modified") != "1":
			feature_layer.remove_feature(feature)
	
	var good_zone_features = good_zone_goc.feature_layer.get_all_features()
	var bad_zone_features = bad_zone_goc.feature_layer.get_all_features()
	
	# This is quite unoptimized, but the low-hanging fruit optimizations (selecting
	# activation_points which are near a good _zone first) did not cause improvements.
	# We'd probably need proper spatial filtering for a significant change.
	# Overall though, this call always seems to take significantly less than 1 second (around
	# 200 ms seems typical, with the bulk of the time used by the `get_all_features` calls).
	# So if we were to optimize, we should probably start somewhere else, e.g. in all the
	# reactions to new features in the UI and 3D world.
	
	var activation_point_and_score = []
	
	var activation_points = activation_layer.get_all_features()
	
	for activation_point in activation_points:
		var activation_point_center = activation_point.get_vector3()
		var activation_point_radius = float(activation_point.get_attribute("radius"))
		
		var score := 0.0
		
		for good_zone in good_zone_features:
			var zone_center = good_zone.get_vector3()
			var zone_radius = float(good_zone.get_attribute("radius"))
			
			var distance = activation_point_center.distance_to(zone_center)
			
			# If the activation point is right inside the go-zone, add a value between 0.5 and 2.0.
			# If the zones are just overlapping, add a value between 0.0 and 1.0.
			if distance < zone_radius:
				score += 0.5 + inverse_lerp(zone_radius + activation_point_radius, 0.0, distance) * 1.5
			elif distance < zone_radius + activation_point_radius:
				score += inverse_lerp(zone_radius + activation_point_radius, zone_radius, distance) * 0.5
		
		for bad_zone in bad_zone_features:
			var zone_center = bad_zone.get_vector3()
			var zone_radius = float(bad_zone.get_attribute("radius"))
			
			var distance = activation_point_center.distance_to(zone_center)
			
			# Essentially the inverse of go-zones.
			# We could add an option to weigh these negative zones higher in case we really want to
			# avoid placing objects in conflicting areas.
			if distance < zone_radius:
				score -= (0.5 + inverse_lerp(zone_radius + activation_point_radius, 0.0, distance) * 1.5) * 2.0
			elif distance < zone_radius + activation_point_radius:
				score -= (inverse_lerp(zone_radius + activation_point_radius, zone_radius, distance) * 0.5) * 2.0
		
		activation_point_and_score.append([activation_point, score])
	
	activation_point_and_score.sort_custom(func(a, b): return a[1] > b[1])
	
	var amount_of_added_features = 0
	
	while true:
		# Exit conditions: feature limit reached
		if amount_of_added_features > FEATURE_LIMIT: break
		
		# Exit condition: score reached
		GameSystem.current_game_mode.game_scores[target_score_name].recalculate_score()
		if GameSystem.current_game_mode.game_scores[target_score_name].is_target_reached(): break
		
		# Exit condition: all points activated
		if activation_point_and_score.size() <= 0: break
		
		var activation_point = activation_point_and_score.pop_front()
		
		# Exit condition: no good points left
		if activation_point[1] <= 0: break
		
		# Activate this point if there isn't already a feature here
		var position = activation_point[0].get_vector3()
		if feature_layer.get_features_near_position(position.x, -position.z, 1.0, 1).size() == 0:
			var new_cluster_feature = feature_layer.create_feature()
			new_cluster_feature.set_vector3(position)
		
		amount_of_added_features += 1
