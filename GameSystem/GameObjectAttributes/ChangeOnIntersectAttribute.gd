extends GameObjectAttribute
class_name ChangeOnIntersectAttribute

# This attribute holds two attributes: one default attribute, and one which is selected instead
# if an object of another GameObjectCollection intersects this one.


var intersecting_game_object_collection: GeoGameObjectCollection
var default_attribute
var intersect_attribute


func _init(initial_name,new_intersecting_game_object_collection,new_default_attribute,new_intersect_attribute):
	name = initial_name
	intersecting_game_object_collection = new_intersecting_game_object_collection
	default_attribute = new_default_attribute
	intersect_attribute = new_intersect_attribute


func get_value(game_object):
	# TODO: Optimize; this is O(n²)
	for other_game_object in intersecting_game_object_collection.game_objects.values():
		if game_object.geo_feature.intersects_with(other_game_object.geo_feature):
			return intersect_attribute.get_value(game_object)
	
	return default_attribute.get_value(game_object)
