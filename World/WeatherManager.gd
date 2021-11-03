extends Node
class_name WeatherManager


signal visibility_changed(new_visibility)
signal cloudiness_changed(new_cloudiness)
signal wind_speed_changed(new_wind_speed)
signal wind_direction_changed(new_wind_direction)
signal unshaded_changed(new_is_unshaded)

var visibility = 0 setget set_visibility # 0..100 = "clear visibility".."strong haziness"
var cloudiness = 0 setget set_cloudiness # 0..100 = "clear sky".."fully overcast"
var wind_speed = 10 setget set_wind_speed # in km/h
var wind_direction = 0 setget set_wind_direction # in degrees
var is_unshaded = false setget set_is_unshaded # true or false; makes objects completely unshaded


func set_visibility(new_visibility):
	visibility = new_visibility
	emit_signal("visibility_changed", visibility)


func set_cloudiness(new_cloudiness):
	cloudiness = new_cloudiness
	emit_signal("cloudiness_changed", cloudiness)


func set_wind_speed(new_wind_speed):
	wind_speed = new_wind_speed
	emit_signal("wind_speed_changed", wind_speed)


func set_wind_direction(new_wind_direction):
	wind_direction = new_wind_direction
	emit_signal("wind_direction_changed", wind_direction)


func set_is_unshaded(new_is_unshaded):
	is_unshaded = new_is_unshaded
	emit_signal("unshaded_changed", is_unshaded)
