extends Object
class_name GameScore

var id := 0
var name := ""

var contributors = []

var value := 0.0
var target := 0.0

signal value_changed(new_value)
signal target_reached


func _init():
	id = GameSystem.acquire_game_object_id()


func add_contributor(game_object_collection: GameObjectCollection, attribute_name, weight = 1.0):
	contributors.append(GameScoreContributor.new(
		game_object_collection, attribute_name, weight
	))


func recalculate_score():
	var sum = 0.0
	
	for contributor in contributors:
		sum += contributor.get_value()
	
	if value != sum:
		value = sum
		emit_signal("value_changed", value)
	
		if value >= target:
			emit_signal("target_reached")


func get_value():
	return value


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
		var sum = 0.0
		
		for game_object in game_object_collection.get_all_game_objects():
			sum += float(game_object.get_attribute(attribute_name)) * weight
		
		return sum
