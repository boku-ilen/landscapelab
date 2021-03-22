extends Node
class_name "ObjectBroker"

# this class manages the loading and saving ('serialization') of the gamestate
# used to setup the initial game and save the progress and result for later
# analysis


# FIXME: do we want to directly save into the geopackage or do we want to specify a target?
func save(game_object: GameObject):
	pass


# FIXME: do we want to indiviudally load a game object (via an identifier) or load the game state as a whole
# FIXME: replacing the currently existing one
func load() -> GameObject:
	pass
