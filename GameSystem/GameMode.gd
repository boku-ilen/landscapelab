extends Object
class_name GameMode


# Map of collection name to GameObjectCollection object
var game_object_collections = {}
var game_scores = {}

signal score_changed(score)
signal score_target_reached(score)


func add_game_object_collection_for_feature_layer(collection_name, feature_layer):
	game_object_collections[collection_name] = GeoGameObjectCollection.new(collection_name, feature_layer)
	return game_object_collections[collection_name]


func add_score(score: GameScore):
	game_scores[score.name] = score
	score.connect("value_changed", self, "_on_score_value_changed", [score])
	score.connect("target_reached", self, "_on_score_target_reached", [score])


func get_starting_position():
	# FIXME: Taken from LayerConfigurator for now; in the future this should probably come from
	#  manually supplied Game Mode settings
	var center_avg := Vector3.ZERO
	var count := 0
	for layer in Layers.layers:
		for geolayer in Layers.layers[layer].render_info.get_geolayers():
			center_avg += geolayer.get_center()
			count += 1
	
	return center_avg / count


func _on_score_value_changed(value, score):
	emit_signal("score_changed", score)


func _on_score_target_reached(value, score):
	emit_signal("score_target_reached", score)
