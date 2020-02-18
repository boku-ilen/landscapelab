extends Node


var _values_settings: JSONParseResult = _parse_values_settings()
var _path_prefix = _values_settings["path-prefix"]


func _parse_values_settings():
	var values_settings_file = File.new()
	var ok: bool = true
	if values_settings_file.open("res://values-settings.json", File.READ) != OK:
		logger.error("BUG: values settings could not be read from json!")
	
	var values_settings_text = values_settings_file.get_as_text()
	values_settings_file.close()
	
	var values_settings_parse = JSON.parse(values_settings_text)
	
	if values_settings_parse.error != OK:
		logger.error("BUG: values settings could not be parsed from json! Is the syntax correct?")
		ok = false
	
	assert(ok)
	
	return values_settings_parse.result


func get_all_values_for_mode(mode: int):
	var all_values_for_mode: Dictionary
	for value in _values_settings["values"]:
		if _values_settings["values"][value]["modes"].has(float(mode)):
			all_values_for_mode[value] = String(_path_prefix + "/" + _values_settings["values"][value]["path"])
	
	return all_values_for_mode
