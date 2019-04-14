tool
extends Node

#
# Parses settings.json in order to allow any script to access any setting
#

var data = parse_data()


func parse_data():
	var data_file = File.new()
	if data_file.open("res://settings.json", File.READ) != OK:
	    logger.error("Settings could not be read from json!")
		
	var data_text = data_file.get_as_text()
	data_file.close()
	
	var data_parse = JSON.parse(data_text)
	
	if data_parse.error != OK:
	    logger.error("Settings could not be parsed from json! Is the syntax correct?")
		
	return data_parse.result


# Get a specific setting by category and label (for example: category 'server', label 'ip')
func get_setting(category, label, default=null):
		
	if not data.has(category):
		logger.error("Invalid setting category: %s" % [category])
	elif not data[category].has(label):
		if default == null:
			logger.error("Setting category %s does not have label %s!" % [category, label])
		else:  # if not found return a default value if it is defined
			return default
	else:
		return data[category][label]
