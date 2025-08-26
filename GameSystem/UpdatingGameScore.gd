extends GameScore
class_name UpdatingGameScore


# Overwrite to recalculate score automatically if the game_object_collection changes in some way
func add_contributor(game_object_collection: GameObjectCollection, attribute_name: String, weight = 1.0, color = Color.GRAY, weight_min = null, weight_max = null):
	super.add_contributor(game_object_collection, attribute_name, weight, color, weight_min, weight_max)
	
	# Connect this GameObjectCollection's changed signal if necessary (it's possible to have two
	# contributors with the same underlying game_object_collection, but different attribute_names)
	if not game_object_collection.is_connected("changed",Callable(self,"recalculate_score")):
		game_object_collection.changed.connect(recalculate_score, CONNECT_DEFERRED)
	
	# FIXME: Hacky
	if attribute_name in game_object_collection:
		if game_object_collection.attributes[attribute_name] is ChangeOnIntersectAttribute:
			game_object_collection.attributes[attribute_name] \
					.intersecting_game_object_collection.changed.connect(recalculate_score, CONNECT_DEFERRED)
	
	# Update the score to reflect this new contributor
	recalculate_score()
