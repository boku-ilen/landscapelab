extends Object
class_name GameScore

var id := 0
var name := ""

var contributors = []

var values_per_contributor = {}

var value := 0.0
var target := 0.0
var icon_name := ""

const DisplayMode = {
	PROGRESSBAR = "ProgressBar",
	STACKEDBAR = "StackedBar",
	ICONTEXT = "IconText"
}
var display_mode = DisplayMode.ICONTEXT

signal value_changed(new_value)
signal target_reached


func _init():
	id = GameSystem.acquire_game_object_id()


func add_contributor(game_object_collection: GameObjectCollection, attribute_name, weight = 1.0, color = Color.gray):
	contributors.append(GameScoreContributor.new(
		game_object_collection, attribute_name, weight
	))
	
	# Connect this GameObjectCollection's changed signal if necessary (it's possible to have two
	# contributors with the same underlying game_object_collection, but different attribute_names)
	if not game_object_collection.is_connected("changed", self, "_recalculate_score"):
		game_object_collection.connect("changed", self, "_recalculate_score")
	
	# Update the score to reflect this new contributor
	_recalculate_score()


func _recalculate_score():
	var sum = 0.0
	
	for contributor in contributors:
		var contributor_value = contributor.get_value()
		var index_name = contributor.get_name()
		
		values_per_contributor[index_name] = contributor_value
		sum += contributor_value
	
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
	# If wished, the score can be applied with an additional color that is used
	# for styling in the UI
	var color_code := Color.gray
	
	func _init(initial_game_object_collection, initial_attribute_name, initial_weight = 1.0):
		game_object_collection = initial_game_object_collection
		attribute_name = initial_attribute_name
		weight = initial_weight
	
	func get_name():
		return game_object_collection.name + " " + attribute_name
	
	func get_value():
		var sum = 0.0
		
		for game_object in game_object_collection.get_all_game_objects():
			sum += float(game_object.get_attribute(attribute_name)) * weight
		
		return sum
