extends Node
class_name JSONParser


func _parse_json(path_to_file: String):
	var settings = File.new()
	var ok: bool = true
	if settings.open(path_to_file, File.READ) != OK:
		logger.error("BUG: One of the settings could not be read from json!")
	
	var settings_text = settings.get_as_text()
	settings.close()
	
	var settings_parse = JSON.parse(settings_text)
	
	if settings_parse.error != OK:
		logger.error("BUG: One of the settings could not be parsed from json! Is the syntax correct?")
		ok = false
	
	assert(ok)
	
	return settings_parse.result
