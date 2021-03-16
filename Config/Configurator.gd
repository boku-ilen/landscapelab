extends Node
class_name Configurator


export(String) var category: String setget set_category
var settings_section  # FIXME: Is this needed?


func set_category(setting_category):
	category = setting_category
	settings_section = Settings.get_setting_section(category)


func get_setting(label, default=null):
	return Settings.get_setting(category, label, default)


# Abstract function for handling a whole settings block 
func _handle_settings():
	pass
