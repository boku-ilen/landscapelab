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


func get_vr_settings_for_mode(my_mode: String):
	for mode in _modes_json:
		if mode["name"] == my_mode:
			return mode["vr"]


func get_base_native(mode: String):
	return get_vr_settings_for_mode(mode)["native-base-dir"]


func get_base_landscape(mode: String):
	return get_vr_settings_for_mode(mode)["landscape-base-dir"]


func get_vr_tools(mode, side) -> Array:
	var tools = []
	for _tool in get_vr_settings_for_mode(mode)[side]["landscape-tools"]:
		tools.append(get_base_landscape(mode).plus_file(_tool))
	for _tool in get_vr_settings_for_mode(mode)[side]["native-tools"]:
		tools.append(get_base_native(mode).plus_file(_tool))
	
	return tools


func get_vr_show_meshes(mode: String, side: String) -> Dictionary:
	var show_hand = get_vr_settings_for_mode(mode)[side]["hand-mesh"]
	var show_controller = get_vr_settings_for_mode(mode)[side]["controller-mesh"]
	
	var gui_finger 
	if show_hand:
		gui_finger = get_vr_settings_for_mode(mode)[side]["gui-finger"]
	else:
		gui_finger = false
	
	return {"hand": show_hand, "controller": show_controller, "gui_finger": gui_finger}
