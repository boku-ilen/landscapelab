extends Node
class_name TableCommunicator

#
# The communication layer between the playing table (via network) and the internal game system.
# Translates the table's **Tokens** to internal **GameObject**s.
#

# Bidirectional dictionaries for mapping tokens (shape + color) to game object collections
var token_to_game_object_collection = {}
var game_object_collection_to_token = {}


func _ready():
	# Inject self into children
	for child in get_children():
		child.set("table_communicator", self)


func get_gamestate_info(request: Dictionary):
	# `request` has "provided_tokens": [{ "shape": .., "color": ...}, ...]
	
	var game_mode = GameSystem.current_game_mode
	
	var response = {
		"keyword": "GAMESTATE_INFO",
		"used_tokens": [],
		"scores": [],
		"existing_tokens": [],
		"start_position_x": 0.0,
		"start_position_y": 0.0,
		"start_extent_x": 0.0,  # height
		"start_extent_y": 0.0,  # width
		"minimap_min_x": 0.0,
		"minimap_min_y": 0.0,
		"minimap_max_x": 0.0,
		"minimap_max_y": 0.0
#		"projection_epsg": 0 
	}
	
	# Set starting position and extent
	var start_position = game_mode.get_starting_position()
	response["start_position_x"] = start_position.x
	response["start_position_y"] = start_position.z
	
	# TODO: Where should this extent come from? Maybe not the game mode, since it's a very
	#  table-specific concept... hardcoded for now
	response["start_extent_x"] = 5000
	response["start_extent_y"] = 5000
	
	var extent = game_mode.get_extent()
	response["minimap_min_x"] = extent[0]
	response["minimap_min_y"] = extent[1]
	response["minimap_max_x"] = extent[2]
	response["minimap_max_y"] = extent[3]
	
	var possible_tokens = request["provided_tokens"]
	var current_possible_token_id := 0
	
#	# Map possible tokens to game object collections within the current game mode
#	for collection in game_mode.game_object_collections.values():
#		if current_possible_token_id < possible_tokens.size():
#			var shape = possible_tokens[current_possible_token_id]["shape"]
#			var color = possible_tokens[current_possible_token_id]["color"]
#
#			if not token_to_game_object_collection.has(shape):
#				token_to_game_object_collection[shape] = {}
#
#			token_to_game_object_collection[shape][color] = collection
#			game_object_collection_to_token[collection] = possible_tokens[current_possible_token_id]
#
#			response["used_tokens"].append({
#				"shape": shape,
#				"color": color,
#				"icon_name": collection.icon_name,  # the icon name corresponding to a Table icon
#				"disappear_after_seconds": 0.0
#			})
#
#			current_possible_token_id += 1
#		else:
#			logger.error("Game Mode would require more possible tokens than provided by this table!")
	
	for collection in game_mode.game_object_collections.values():
		if not collection.desired_shape in token_to_game_object_collection:
			token_to_game_object_collection[collection.desired_shape] = {}
		token_to_game_object_collection[collection.desired_shape][collection.desired_color] = collection
		response["used_tokens"].append({
			"shape": collection.desired_shape,
			"color": collection.desired_color,
			"icon_name": collection.icon_name,
			"disappear_after_seconds": 0.0
		})
	
	# Write scores into the response
	for score in game_mode.game_scores.values():
		response["scores"].append({
			"score_id": score.id,
			"name": score.name,
			"initial_value": score.value,
			"target_value": score.target
		})
	
	# Write existing tokens into the response
	for collection in game_mode.game_object_collections.values():
#		var token = game_object_collection_to_token[collection]
		
		for game_object in collection.get_all_game_objects():
			response["existing_tokens"].append({
				"object_id": game_object.id,
				"position_x": game_object.get_position().x,
				"position_y": -game_object.get_position().z,
				"shape": collection.desired_shape,
				"color": collection.desired_color,
				"data": []  # optional
			})
	
	return response
