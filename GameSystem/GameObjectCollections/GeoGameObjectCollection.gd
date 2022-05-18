extends GameObjectCollection
class_name GeoGameObjectCollection

#
# A collection of multiple GeoGameObjects of the same type.
# Has a 1:1 relationship to a Layer.
#

var attributes = {}
var feature_layer


func _init(initial_name, initial_feature_layer).(initial_name):
	feature_layer = initial_feature_layer
	
	# Register all existing features
	for feature in feature_layer.get_all_features():
		_add_game_object(feature)
	
	# Register future features automatically
	feature_layer.connect("feature_added", self, "_add_game_object")
	feature_layer.connect("feature_removed", self, "_remove_game_object")


func _add_game_object(feature):
	var game_object_for_feature = GameSystem.create_game_object_for_geo_feature(feature, self)
	game_objects[game_object_for_feature.id] = game_object_for_feature
	
	# TODO: Currently we only handle this signal, but we'd want to react to other changes as well
	# This might warrant an addition in Geodot (a general "changed" signal)
	if feature.has_signal("point_changed"):
		feature.connect("point_changed", self, "_on_feature_changed")
	
	emit_signal("changed")


func _on_feature_changed():
	emit_signal("changed")


func _remove_game_object(feature):
	# TODO: do this more elegantly without iterating over everything
	# find corresponding object
	var corresponding_game_object
	
	for game_object in game_objects.values():
		if game_object.geo_feature == feature:
			corresponding_game_object = game_object
	
	GameSystem.apply_game_object_removal(name, corresponding_game_object.id)
	
	emit_signal("changed")


# FIXME: Maybe we should have a `add_attribute_mapping` instead and leave the object creation up to the user.
#  This would allow some more flexibility and be less maintainance work
func add_explicit_attribute_mapping(attribute_name, geo_attribute_name):
	attributes[attribute_name] = ExplicitGameObjectAttribute.new(attribute_name, geo_attribute_name)


func add_implicit_attribute_mapping(attribute_name, raster_layer):
	attributes[attribute_name] = ImplicitGameObjectAttribute.new(attribute_name, raster_layer)


# Attributes

# General definition of an attribute which game objects within one collection can have
class GameObjectAttribute:
	var name := ""
		
	# To be implemented
	func get_value(game_object):
		pass

# Explicit attributes correspond directly to attributes of features.
# This class thus remembers the name of the corresponding attribute in the GeoFeature.
class ExplicitGameObjectAttribute extends GameObjectAttribute:
	var geo_attribute_name
	
	func _init(initial_name, initial_geo_attribute_name):
		name = initial_name
		geo_attribute_name = initial_geo_attribute_name
	
	func get_value(game_object):
		return game_object.geo_feature.get_attribute(geo_attribute_name)


# Implicit attributes are values at the game object's position in a different raster layer.
# This class thus remembers the raster layer from which to fetch these values.
class ImplicitGameObjectAttribute extends GameObjectAttribute:
	var raster_layer
	
	func _init(initial_name, initial_raster_layer):
		name = initial_name
		raster_layer = initial_raster_layer
	
	func get_value(game_object):
		var position = game_object.geo_feature.get_vector3()
		return raster_layer.get_value_at_position(position.x, -position.z)
