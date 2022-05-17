extends Object
class_name GameMode


# Map of collection name to GameObjectCollection object
var game_object_collections = {}
var game_scores = {}

var extent = [0.0, 0.0, 0.0, 0.0]

signal score_changed(score)
signal score_target_reached(score)


func add_game_object_collection(collection):
	game_object_collections[collection.name] = collection


func add_game_object_collection_for_feature_layer(collection_name, feature_layer):
	var collection = GeoGameObjectCollection.new(collection_name, feature_layer)
	add_game_object_collection(collection)
	return collection


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


func set_extent(min_x, min_y, max_x, max_y):
	extent[0] = min_x
	extent[1] = min_y
	extent[2] = max_x
	extent[3] = max_y


# Returns the extent as an array containing min_x, min_y, max_x, max_y
func get_extent():
	return extent


func _on_score_value_changed(value, score):
	emit_signal("score_changed", score)


func _on_score_target_reached(value, score):
	emit_signal("score_target_reached", score)
