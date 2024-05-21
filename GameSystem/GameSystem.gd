extends Node


var current_game_mode: GameMode :
	get:
		return current_game_mode
	set(new_game_mode):
		# Disconnect previous signals
		if current_game_mode:
			current_game_mode.disconnect("score_changed",Callable(self,"_on_score_changed"))
			current_game_mode.disconnect("score_target_reached",Callable(self,"_on_score_target_changed"))
		
		if not new_game_mode in game_modes:
			game_modes.append(new_game_mode)
		
		current_game_mode = new_game_mode
	
		current_game_mode.connect("score_changed",Callable(self,"_on_score_changed"))
		current_game_mode.connect("score_target_reached",Callable(self,"_on_score_target_changed"))
		
		game_mode_changed.emit()


var game_modes: Array[GameMode] = []

var _next_game_object_id := 0
var _game_objects = {}

signal score_changed(score)
signal score_target_reached(score)

signal game_mode_changed


func save():
	for game_mode in game_modes:
		for collection in current_game_mode.game_object_collections.values():
			if "feature_layer" in collection:
				collection.feature_layer.save_new("./game_layer_%s_%s.shp" % [collection.name, floor(Time.get_unix_time_from_system())])


func activate_next_game_mode():
	if game_modes.is_empty(): 
		logger.error("No game modes have been defined, cannot move to next state.")
		return
	
	if current_game_mode == null:
		current_game_mode = game_modes[0]
		return
		
	var current_game_mode_idx = game_modes.find(current_game_mode)
	
	if current_game_mode_idx >= game_modes.size() - 1: return
	
	current_game_mode = game_modes[(current_game_mode_idx + 1) % game_modes.size()]


func _on_score_changed(score):
	emit_signal("score_changed", score)


func _on_score_target_reached(score):
	emit_signal("score_target_reached", score)


func create_new_game_object(collection, position := Vector3.ZERO):
	# FIXME: This if should be removed, it's a hacky way to allow the PlayerGameObjectCollection to
	#  move the player checked "NEW_TOKEN" while allowing the actual creation of new objects in
	#  GeoGameObjectCollections
	if is_instance_of(collection, PlayerGameObjectCollection):
		collection.game_objects.values()[0].set_position(position)
		return collection.game_objects.values()[0]
	else:
		return create_new_geo_game_object(collection, position)


func create_new_geo_game_object(collection, position := Vector3.ZERO):
	# FIXME: Feels hacky and would be a race condition in multi-threaded code. The problem is that
	#  We don't actually create a game object until `create_feature` causes `feature_added` to be
	#  emitted, which calls `create_game_object_for_geo_feature`. But we're sure that it will be
	#  created and we want the ID here
	var id = _next_game_object_id
	
	# Check whether it is allowed to create a game object here
	for creation_condition in collection.creation_conditions.values():
		if not creation_condition.is_creation_allowed_at_position(position):
			return null
	
	var new_feature = collection.feature_layer.create_feature()
	
	# TODO: Could this be generalized? We do need the position here in order to check the creation
	# conditions, so we can't just create an object and set it later
	if new_feature.has_method("set_vector3") and position != Vector3.ZERO:
		new_feature.set_vector3(position)
	
	# No need to do anything else because the collection reacts to the `feature_added` signal
	
	return _game_objects[id]


func remove_game_object(game_object):
	var collection = game_object.collection
	
	# TODO: Find a cleaner way to differentiate here; maybe use duck typing
	if "feature_layer" in collection:
		collection.feature_layer.remove_feature(game_object.geo_feature)
		apply_game_object_removal(collection.name, game_object.id)


# Returns the game object that corresponds to the given ID, or null if it doesn't exist.
func get_game_object(id):
	return _game_objects.get(int(id))


# Returns a unique Game Object ID which is ensured not to be returned again.
func acquire_game_object_id():
	var id = _next_game_object_id
	_next_game_object_id += 1
	
	return id


func create_game_object_for_geo_feature(game_object_class, geo_feature, collection):
	var id = acquire_game_object_id()
	
	var game_object = game_object_class.new(id, collection, geo_feature)
	_game_objects[id] = game_object
	
	return game_object


func get_game_object_for_geo_feature(geo_feature):
	# FIXME: Implement properly
	for go in _game_objects.values():
		if go is GeoGameObject:
			if "get_vector3" in go.geo_feature:
				if go.geo_feature.get_vector3() == geo_feature.get_vector3():
					return go


func apply_game_object_removal(collection_name, game_object_id):
	if collection_name in current_game_mode.game_object_collections:
		var collection = current_game_mode.game_object_collections[collection_name]
		collection.game_objects.erase(game_object_id)
		_game_objects.erase(game_object_id)


func _on_new_game_layer(_layer):
	pass
