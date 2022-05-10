extends Node


var current_game_mode: GameMode

var _next_game_object_id := 0
var _game_objects = {}


func _ready():
	# TODO: Layers.connect("new_game_layer", self, "_on_new_game_layer")
	pass


func create_new_game_object(collection_name):
	var collection = current_game_mode.game_object_collections[collection_name]
	var id = _next_game_object_id
	collection.feature_layer.create_feature()
	# No need to do anything else because the collection reacts to the `feature_added` signal
	
	return _game_objects[id]


func remove_game_object(game_object):
	var collection = game_object.collection
	
	collection.feature_layer.remove_feature(game_object.geo_feature)
	
	apply_game_object_removal(collection.name, game_object.id)


func get_game_object(id):
	return _game_objects[int(id)]


func create_game_object_for_geo_feature(geo_feature):
	var game_object = GameObject.new(_next_game_object_id, geo_feature)
	_game_objects[_next_game_object_id] = game_object
	
	_next_game_object_id += 1
	
	return game_object


func apply_game_object_removal(collection_name, game_object_id):
	var collection = current_game_mode.game_object_collections[collection_name]
	collection.game_objects[game_object_id] = null
	_game_objects[game_object_id] = null


func _on_new_game_layer(layer):
	pass
