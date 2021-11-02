extends Node
class_name WeatherManager


signal visibility_changed(new_visibility)
signal cloudiness_changed(new_cloudiness)
signal unshaded_changed(new_is_unshaded)

var visibility = 0 setget set_visibility # 0..100 = "clear visibility".."strong haziness"
var cloudiness = 0 setget set_cloudiness # 0..100 = "clear sky".."fully overcast"
var is_unshaded = false setget set_is_unshaded # true or false; makes objects completely unshaded


func set_visibility(new_visibility):
	visibility = new_visibility
	emit_signal("visibility_changed", visibility)


func set_cloudiness(new_cloudiness):
	cloudiness = new_cloudiness
	emit_signal("cloudiness_changed", cloudiness)


func set_is_unshaded(new_is_unshaded):
	is_unshaded = new_is_unshaded
	emit_signal("unshaded_changed", is_unshaded)
