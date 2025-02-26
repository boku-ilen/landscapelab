extends Object
class_name GameObjectAttribute


var name := ""
var allow_change = false
var show_in_config = true
var icon_settings := {}

var min: float
var max: float
var default: float


# To be implemented
func get_value(_game_object):
	pass


# To be implemented
func set_value(_game_object, _new_value):
	pass
