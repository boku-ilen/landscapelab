extends Object
class_name GameScore

var id := 0
var name := ""

var contributors = []

var value := 0.0
var target := 0.0


func get_value():
	var sum = 0.0
	
	for contributor in contributors:
		sum += contributor.get_value()
	
	return sum


func is_target_reached():
	return get_value() >= target


class GameScoreContributor:
	var game_object_collection: GameObjectCollection
	var attribute_name: String
	var weight := 1.0
	
	func _init(initial_game_object_collection, initial_attribute_name, initial_weight = 1.0):
		game_object_collection = initial_game_object_collection
		attribute_name = initial_attribute_name
		weight = initial_weight
	
	func get_value():
		# TODO: Cache the value and only recalculate if the game objects in the collection have changed
		
		var sum = 0.0
		
		for game_object in game_object_collection.get_all_game_objects():
			sum += game_object.get_attribute(attribute_name)
		
		return sum
