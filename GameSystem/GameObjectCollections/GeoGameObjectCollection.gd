extends GameObjectCollection
class_name GeoGameObjectCollection

#
# A collection of multiple GeoGameObjects of the same type.
# Has a 1:1 relationship to a Layer.
#

var attributes = {}
var feature_layer

signal game_object_added(new_game_object)
signal game_object_removed(removed_game_object)


func _init(initial_name, initial_feature_layer):
	super._init(initial_name)
	
	feature_layer = initial_feature_layer
	
	# Register all existing features
	for feature in feature_layer.get_all_features():
		_add_game_object(feature)
	
	# Register future features automatically
	feature_layer.connect("feature_added",Callable(self,"_add_game_object"))
	feature_layer.connect("feature_removed",Callable(self,"_remove_game_object"))


func get_nearby_game_objects(position, radius):
	return feature_layer.get_features_near_position(
		position.x,
		position.z,
		radius,
		10000
	)


func remove_nearby_game_objects(position, radius):
	for feature in get_nearby_game_objects(position, radius):
		feature_layer.remove_feature(feature)


func _add_game_object(feature):
	var game_object_for_feature = GameSystem.create_game_object_for_geo_feature(GeoGameObject, feature, self)
	game_objects[game_object_for_feature.id] = game_object_for_feature
	
	feature.feature_changed.connect(_on_feature_changed)
	
	emit_signal("game_object_added", game_object_for_feature)
	emit_signal("changed")


func _on_feature_changed():
	emit_signal("changed")


func _remove_game_object(feature):
	# TODO: do this more elegantly without iterating over everything
	# find corresponding object
	var corresponding_game_object
	
	for game_object in game_objects.values():
		if game_object.geo_feature.get_id() == feature.get_id():
			corresponding_game_object = game_object
	
	if corresponding_game_object:
		GameSystem.apply_game_object_removal(name, corresponding_game_object.id)
		
		emit_signal("game_object_removed", corresponding_game_object)
		emit_signal("changed")


func add_attribute_mapping(attribute):
	attributes[attribute.name] = attribute
	emit_signal("changed")

