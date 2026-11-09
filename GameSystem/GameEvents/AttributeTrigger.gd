extends EventTrigger
class_name AttributeTrigger


var game_object_collection: GameObjectCollection
var condition: String


func _init(initial_game_object_collection, initial_condition):
	game_object_collection = initial_game_object_collection
	condition = initial_condition
	
	game_object_collection.game_object_added.connect(_on_new_game_object, CONNECT_DEFERRED)


func _on_new_game_object(new_game_object: GameObject):
	if new_game_object.parse_expression(condition):
		triggered.emit()
