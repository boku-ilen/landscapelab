tool
extends JSONParser

#
# Parses default-settings.json in order to allow any script to access any setting
# TODO: an optional readout of the LL_settings table in the geopackage can overwrite the default settings
#

var user_config: JSONParseResult = parse_user_data()
var default_data: JSONParseResult = _parse_json("res://default-settings.json")


func parse_user_data():
	# TODO: implement reading the geopackage table LL_settings
	pass


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
