extends Object
class_name GameMode


# Map of collection name to GameObjectCollection object
var game_object_collections = {}
var game_scores = {}
var game_views = {}

var token_to_game_object_collection = {}

var current_view: GameView
var extent = [0.0, 0.0, 0.0, 0.0]

signal view_activated(view)
signal score_changed(score)
signal score_target_reached(score)


func add_game_object_collection(collection):
	game_object_collections[collection.name] = collection


func add_game_object_collection_for_feature_layer(collection_name, feature_layer):
	var collection = GeoGameObjectCollection.new(collection_name, feature_layer)
	add_game_object_collection(collection)
	return collection


func add_cluster_game_object_collection(collection_name, feature_layer, location_layer, instance_goc):
	var collection = GameObjectClusterCollection.new(collection_name, feature_layer, location_layer, instance_goc)
	add_game_object_collection(collection)
	return collection


func add_score(score: GameScore):
	game_scores[score.name] = score
	score.connect("value_changed",Callable(self,"_on_score_value_changed").bind(score))
	score.connect("target_reached",Callable(self,"_on_score_target_reached").bind(score))


func get_starting_position():
	Layers.recalculate_center()
	return Layers.current_center


func set_extent(min_x, min_y, max_x, max_y):
	extent[0] = min_x
	extent[1] = min_y
	extent[2] = max_x
	extent[3] = max_y


# Returns the extent as an array containing min_x, min_y, max_x, max_y
func get_extent():
	return extent


func activate_view(view_name):
	current_view = game_views[view_name]
	current_view.activate()
	
	emit_signal("view_activated", current_view)


func _on_score_value_changed(score):
	emit_signal("score_changed", score)


func _on_score_target_reached(score):
	emit_signal("score_target_reached", score)
