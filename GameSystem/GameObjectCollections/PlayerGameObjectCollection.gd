extends GameObjectCollection
class_name PlayerGameObjectCollection

#
# Game Object Collection which holds exactly one Game Object: the Player.
#


func _init(initial_name, initial_player_game_node).(initial_name):
	var id = GameSystem.acquire_game_object_id()
	var player_game_object = PlayerGameObject.new(id, self, initial_player_game_node)
	game_objects[id] = player_game_object
	
	# FIXME: We're accessing a "private" variable here, so something needs to be changed
	GameSystem._game_objects[id] = player_game_object
