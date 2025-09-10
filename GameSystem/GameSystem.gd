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
		
		current_game_mode.activate()


var game_modes: Array[GameMode] = []
var game_mode_names_to_objects: Dictionary[String, GameMode] = {}

var _next_game_object_id := 0
var _game_objects = {}
var save_dir := "saves-test"
var user_save_dir := "user://%s" % [save_dir]

var was_loaded: bool = false

signal score_changed(score)
signal score_target_reached(score)

signal game_mode_changed


func save():
	if not DirAccess.dir_exists_absolute(user_save_dir): DirAccess.make_dir_absolute(user_save_dir)
	
	var config = ConfigFile.new()
	
	for game_mode in game_modes:
		for collection in game_mode.game_object_collections.values():
			if "feature_layer" in collection:
				var save_path = OS.get_user_data_dir().path_join("/%s/game_layer_%s_%s.gpkg" % [save_dir, collection.name, floor(Time.get_unix_time_from_system())])
				collection.feature_layer.save_new(save_path)
				
				# Remember "last save file location" for this feature layer
				config.set_value("Savestate", collection.name, save_path)
			
			if "cluster_points_layer" in collection:
				# We handle the "cluster_points_layer" of clusters separately
				# We need to save them to remember which ones have been activated
				var save_path = OS.get_user_data_dir().path_join("/%s/cluster_point_layer_%s_%s.gpkg" % [save_dir, collection.name, floor(Time.get_unix_time_from_system())])
				collection.cluster_points_layer.save_new(save_path)
				
				# Remember "last save file location" for this layer
				config.set_value("Cluster Point Savestate", collection.name, save_path)
	
	config.save("user://%s/savestate.cfg" % [save_dir])



func load_last_save():
	var config = ConfigFile.new()
	var load_result = config.load("user://%s/savestate.cfg" % [save_dir])
	
	if not load_result == OK: return
	
	for game_mode in game_modes:
		for collection in game_mode.game_object_collections.values():
			if "cluster_points_layer" in collection:
				# First, load cluster points so that activated points are not instantiated again
				# by clusters later
				var last_cluster_point_save_path = config.get_value("Cluster Point Savestate", collection.name)
				
				# Load features from that file into this layer
				var dataset = Geodot.get_dataset(last_cluster_point_save_path)
				var layer = dataset.get_feature_layers()[0]
				
				# Set modified attributes
				for feature in layer.get_all_features():
					var this_feature = collection.cluster_points_layer.get_feature_by_id(feature.get_id())
					var attributes = feature.get_attributes()
					
					for attribute_name in feature.get_attributes().keys():
						this_feature.set_attribute(attribute_name, attributes[attribute_name])
			
			if "feature_layer" in collection:
				var last_save_path = config.get_value("Savestate", collection.name)
				
				# Load features from that file into this feature_layer
				var dataset = Geodot.get_dataset(last_save_path)
				var layer = dataset.get_feature_layers()[0]
				
				# Remove all previously loaded features 
				for feature in collection.feature_layer.get_all_features():
					collection.feature_layer.remove_feature(feature)
				
				for feature in layer.get_all_features():
					# TODO: Might be nice to generalize this by adding feature.load_from_feature()
					#  or even something like layer.load_from_layer() to Geodot
					var position = feature.get_vector3()
					var attributes = feature.get_attributes()
					
					var new_feature = collection.feature_layer.create_feature()
					new_feature.set_vector3(position)
					for attribute_name in attributes.keys():
						new_feature.set_attribute(attribute_name, attributes[attribute_name])


func activate_next_game_mode():
	if game_modes.is_empty(): 
		logger.error("No game modes have been defined, cannot move to next state.")
		return
	
	if current_game_mode == null:
		current_game_mode = game_modes[0]
		return
		
	var current_game_mode_idx = game_modes.find(current_game_mode)
	
	#if current_game_mode_idx >= game_modes.size() - 1: return
	
	current_game_mode = game_modes[(current_game_mode_idx + 1) % game_modes.size()]


func activate_game_mode_by_name(game_mode_name: String):
	if not game_mode_name in game_mode_names_to_objects:
		logger.error("No game mode with the name %s exists!" % [game_mode_name])
		return
	
	current_game_mode = game_mode_names_to_objects[game_mode_name]


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
	
	# Set the "modified" attribute since this is a manually created game object
	# FIXME: once we have something like "has_attribute", check that first
	new_feature.set_attribute("modified", "1")
	
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
	
	# Apply default attribute values
	for attribute: GameObjectAttribute in collection.attributes.values():
		if attribute.default > 0 and float(attribute.get_value(game_object)) == 0:
			attribute.set_value(game_object, attribute.default)
	
	return game_object


func get_game_object_for_geo_feature(geo_feature):
	# FIXME: Implement properly
	for go in _game_objects.values():
		if go is GeoGameObject:
			if "get_vector3" in go.geo_feature:
				if go.geo_feature.get_vector3() == geo_feature.get_vector3() \
						and go.geo_feature.get_id() == geo_feature.get_id():
					return go


func apply_game_object_removal(collection_name, game_object_id):
	for game_mode in game_modes:
		if collection_name in game_mode.game_object_collections:
			var collection = game_mode.game_object_collections[collection_name]
			collection.game_objects.erase(game_object_id)
			_game_objects.erase(game_object_id)


func _on_new_game_layer(_layer):
	pass
