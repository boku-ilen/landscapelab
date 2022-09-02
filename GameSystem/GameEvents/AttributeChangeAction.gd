extends EventAction
class_name AttributeChangeAction


var geo_game_object_collection_name
var new_attribute


func apply(game_mode: GameMode):
	var game_object_collection := game_mode.game_object_collections[geo_game_object_collection_name] as GeoGameObjectCollection
	
	# The name of the new attribute should match the name of the old one to replace.
	# That way, it is overwritten rather than added.
	game_object_collection.add_attribute_mapping(new_attribute)
