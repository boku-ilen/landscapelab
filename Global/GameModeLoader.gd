extends JSONParser


var _settings: Dictionary = _parse_json("res://game-mode-settings.json")
var _values_settings = _settings["values"]
var _tool_settings = _settings["tools"]

var _modes_json: Array = _parse_json("res://game-modes.json")


# Returns an Array mapping a mode ID to all its data.
func get_modes() -> Array:
	return _modes_json


# Returns an Array mapping a mode ID to its name.
func get_mode_names() -> Array:
	var modes = []
	
	for gamemode in _modes_json:
		modes.append(gamemode["name"])
	
	return modes


func get_all_values_for_mode(mode: int):
	var all_values_for_mode: Dictionary
	for value in _values_settings["modules"]:
		if _values_settings["modules"][value]["modes"].has(float(mode)):
			all_values_for_mode[value] = String(_values_settings["path-prefix"] +
				 "/" + _values_settings["modules"][value]["path"])
	
	return all_values_for_mode


func get_all_tools_for_mode(mode: int):
	var all_tools_for_mode = []
	for _tool in _tool_settings:
		if _tool_settings[_tool]["modes"].has(float(mode)):
			all_tools_for_mode.append(_tool)
	
	return all_tools_for_mode


func get_startup_mode():
	return _settings["game-mode"]
