tool
extends JSONParser

#
# Parses default-settings.json in order to allow any script to access any setting
# TODO: an optional readout of the LL_settings table in the geopackage can overwrite the default settings
#

const default_configuration_path: String = "res://configuration.ini"
const scenario_config_path: String = "res://sample1_2.gpkg"
const user_config_path: String = "res://user-config.ini"

var config = ConfigFile.new()
var user_config = ConfigFile.new()

var software_config: Dictionary = {
	"meta": {
		"version": "v0.5.0-dev",
		"usage": "debug"
	},
	"logger": {
		"max-messages-in-stream": 20,
		"default-level": 0
	}
}


func _init():
	load_settings()


# Settings are overriden in the following order:
# defaults < user_config < scenario_config (package) < command line
func load_settings():
	logger.info("Setting up configuration ...")
	
	_load_defaults()
	_load_from_user_config()
	_load_from_scenario_config()
	_load_from_cl()


func _load_defaults():
	var err = config.load(default_configuration_path)
	if err != OK:
		logger.error("Default configuration could not be loaded. Is there a file configuration.ini?")
		assert(true)


func _load_from_user_config():
	var err = user_config.load(user_config_path)
	if err != OK:
		logger.error("User-configuration could not be loaded. Is there a file user-config.ini?")
		return
	
	for section in user_config.get_sections():
		for key in user_config.get_section_keys(section):
			if config.get_value(section, key) != null:
				config.set_value(section, key, user_config.get_value(section, key))


func _load_from_scenario_config():
	pass


# TODO: Loading from command line like this requires the configuration to have unique keys even in different sections
func _load_from_cl():
	var cl_args = Array(OS.get_cmdline_args())
	
	for arg in cl_args:
		var arg_key = arg.substr(0, arg.find('='))
		var arg_value = arg.substr(arg.find('='))
		for section in config.get_sections():
			for key in config.get_section_keys(section):
				if key == arg_key:
					config.set_value(section, key, arg_value)


func save_user_settings():
	for section in config.get_sections():
		if section.find("user-config") != -1:
			for key in config.get_section_keys(section):
				user_config.set_value(section, key, config.get_value(section, key))
	
	user_config.save()


# Get a specific setting by category and label (for example: category 'server', label 'ip')
func get_setting(section, key , default=null):
	if not config.has_section(section):
		logger.error("BUG: Invalid setting section: %s" % [section])
	elif not config.has_section_key(section, key):
		if default == null:
			logger.error("BUG: Setting section %s does not have key %s!" % [section, key])
	
	return config.get_value(section, key, default)


func get_setting_section(section_name):
	if not config.has_section(section_name):
		logger.error("BUG: Invalid setting section: %s" % [section_name])
		return null
	
	var section: Dictionary
	for key in config.get_section_keys(section_name):
		section[key] = config.get_value(section_name, key)
		
	return section
