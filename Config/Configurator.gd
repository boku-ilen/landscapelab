extends Node
class_name Configurator


export(String) var category: String setget set_category
var setting_block


func set_category(setting_category):
	category = setting_category
	setting_block = Settings.get_setting_block(category)


func get_setting(label, default=null):
	return Settings.get_setting(category, label, default)


# Abstract function for handling a whole settings block 
func _handle_settings():
	pass
