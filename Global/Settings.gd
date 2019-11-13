tool
extends Node

#
# Parses default-settings.json in order to allow any script to access any setting
# TODO: an optional settings.json in the working directory can overwrite the default settings
#

var user_config: JSONParseResult = parse_user_data()
var default_data: JSONParseResult = parse_default_data()


func parse_user_data():
	var config = ConfigFile.new()
	var err = config.load("user://settings.ini")
	if err == OK: 
		return config
	else:
		logger.info("Could not find a user configuration file so working with the defaults")


# reads the bundled default settings json file and makes the data available
func parse_default_data():
	var default_data_file = File.new()
	if default_data_file.open("res://default-settings.json", File.READ) != OK:
		logger.error("BUG: default settings could not be read from json!")
		
	var default_data_text = default_data_file.get_as_text()
	default_data_file.close()
	
	var default_data_parse = JSON.parse(default_data_text)
	
	if default_data_parse.error != OK:
		logger.error("BUG: default settings could not be parsed from json! Is the syntax correct?")
		
	return default_data_parse.result


# Get a specific setting by category and label (for example: category 'server', label 'ip')
func get_setting(category, label, default=null):
		
	if not default_data.has(category):
		logger.error("BUG: Invalid setting category: %s" % [category])
	elif not default_data[category].has(label):
		if default == null:
			logger.error("BUG: Setting category %s does not have label %s!" % [category, label])
		else:  # if not found return a default value if it is defined
			return default
	else:
		# if there is a user config label with the same name prioritize this configuration
		if user_config:
			return user_config.get_value(category, label, default_data[category][label])
		# if not we provide the default settings
		else:
			return default_data[category][label]
