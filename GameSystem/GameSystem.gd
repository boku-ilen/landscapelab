extends Node


var current_game_mode: GameMode setget set_current_game_mode

var _next_game_object_id := 0
var _game_objects = {}

signal score_changed(score)
signal score_target_reached(score)


func _ready():
	# TODO: Layers.connect("new_game_layer", self, "_on_new_game_layer")
	pass


func set_current_game_mode(new_game_mode):
	# Disconnect previous signals
	if current_game_mode:
		current_game_mode.disconnect("score_changed", self, "_on_score_changed")
		current_game_mode.disconnect("score_target_reached", self, "_on_score_target_changed")
	
	current_game_mode = new_game_mode
	
	current_game_mode.connect("score_changed", self, "_on_score_changed")
	current_game_mode.connect("score_target_reached", self, "_on_score_target_changed")


func _on_score_changed(score):
	emit_signal("score_changed", score)


func _on_score_target_reached(score):
	emit_signal("score_target_reached", score)


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


func create_game_object_for_geo_feature(geo_feature, collection):
	var game_object = GameObject.new(_next_game_object_id, geo_feature, collection)
	_game_objects[_next_game_object_id] = game_object
	
	_next_game_object_id += 1
	
	return game_object


func apply_game_object_removal(collection_name, game_object_id):
	var collection = current_game_mode.game_object_collections[collection_name]
	collection.game_objects.erase(game_object_id)
	_game_objects.erase(game_object_id)


func _on_new_game_layer(layer):
	pass
