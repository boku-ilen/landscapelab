extends Resource
class_name Layer


#
# Does caching and some logic, is the basic resource for all other scenes that work with layers
# 

var is_rendered: bool = false
var is_scored: bool = false
var is_visible: bool = true setget set_visible

var name: String

var fields: Dictionary = {}

signal visibility_changed(visible)


func set_visible(visible: bool):
	is_visible = visible
	emit_signal("visibility_changed", is_visible)
