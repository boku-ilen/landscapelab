extends Object
class_name GameMode


# Map of collection name to GameObjectCollection object
var game_object_collections = {}
var game_scores = {}


func add_game_object_collection_for_feature_layer(collection_name, feature_layer):
	game_object_collections[collection_name] = GameObjectCollection.new(collection_name, feature_layer)
	return game_object_collections[collection_name]


func add_score(score):
	game_scores[score.name] = score
