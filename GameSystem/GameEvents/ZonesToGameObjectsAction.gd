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


func apply(_game_mode: GameMode):
	# Delete all previous features
	# FIXME: Maybe don't do that and try to preserve changes made there, in case the game mode is
	#  switched back and forth
	for feature in feature_layer.get_all_features():
		feature_layer.remove_feature(feature)
	
	var good_zone_features = good_zone_goc.feature_layer.get_all_features()
	var bad_zone_features = bad_zone_goc.feature_layer.get_all_features()
	
	# FIXME: This method of checking points to activate is wastefully slow.
	#  I tried optimizing by first selecting activation_points which are near a good_zone, but this
	#  ended up not really causing an improvement. I guess we would need full spatial filtering
	#  for something better
	
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
			
			# If the object is somewhat close, add a fixed value of 2.0 as well as a value between
			#  0.0 and 1.0 depending on the distance, so that we prefer points closer to the zone
			#  centers
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
		
		activation_point_and_score.append([activation_point, score])
	
	activation_point_and_score.sort_custom(func(a, b): return a[1] > b[1])
	
	while true:
		# Exit condition: score reached
		GameSystem.current_game_mode.game_scores[target_score_name].recalculate_score()
		if GameSystem.current_game_mode.game_scores[target_score_name].is_target_reached(): break
		
		# Exit condition: all points activated
		if activation_point_and_score.size() <= 0: break
		
		var activation_point = activation_point_and_score.pop_front()
		
		# Exit condition: no good points left
		if activation_point[1] <= 0: break
		
		# Activate this point
		var new_cluster_feature = feature_layer.create_feature()
		new_cluster_feature.set_vector3(activation_point[0].get_vector3())
