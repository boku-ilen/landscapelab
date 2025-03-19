extends Object
class_name GameScore

var id := 0
var name := ""

var contributors = []

var values_per_contributor = {}

var value := 0.0
var target := 0.0
# e.g.: energy-provided households
# descriptor -> energy-symbol; subject -> household
var icon_descriptor := ""
var icon_subject := ""
var unit := ""

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


func add_contributor(game_object_collection: GameObjectCollection, attribute_name, weight = 1.0, color = Color.GRAY, weight_min = null, weight_max = null):
	var new_contributor = GameScoreContributor.new(
		game_object_collection, attribute_name, weight, color
	)
	
	if weight_min and weight_max:
		new_contributor.weight_changable = true
		new_contributor.weight_interval_start = weight_min
		new_contributor.weight_interval_end = weight_max
	
	contributors.append(new_contributor)
	new_contributor.connect("weight_changed",Callable(self,"recalculate_score"))


func recalculate_score():
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
	var weight := 1.0 :
		get:
			return weight
		set(w):
			weight = w
			emit_signal("weight_changed")
	
	var weight_changable := false
	var weight_interval_start := 0.1
	var weight_interval_end := 0.1
	# If wished, the score can be applied with an additional color that is used
	# for styling in the UI
	var color_code := Color.GRAY
	
	signal weight_changed
	
	func _init(initial_game_object_collection,initial_attribute_name,initial_weight = 1.0,color = Color.GRAY):
		game_object_collection = initial_game_object_collection
		attribute_name = initial_attribute_name
		weight = initial_weight
		color_code = color
	
	func get_name():
		return game_object_collection.name + " " + attribute_name
	
	func get_value():
		var sum = 0.0
		
		for game_object in game_object_collection.get_all_game_objects():
			sum += float(game_object.get_attribute(attribute_name)) * weight
		
		return sum
