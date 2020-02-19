extends JSONParser


var _settings: JSONParseResult = _parse_json("res://game-mode-settings.json")
var _values_settings = _settings["values"]
var _tool_settings = _settings["tools"]


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
