extends Object
class_name GameObjectCollection

#
# A collection of game objects.
#

var name = ""
var icon_name = ""
var game_objects = {}
var creation_conditions = {}

# Table-specific
# FIXME: Should be somewhere else, GameObjectCollections shouldn't need to know about tables
var desired_color
var desired_shape

signal changed # Emitted whenever there is any change in the collection


func _init(initial_name):
	name = initial_name


func get_game_object(id):
	return game_objects[id]


func get_all_game_objects():
	return game_objects.values()


func add_creation_condition(creation_condition):
	creation_conditions[creation_condition.name] = creation_condition
