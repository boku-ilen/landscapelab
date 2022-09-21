extends Node
class_name WeatherManager


signal visibility_changed(new_visibility)
signal cloudiness_changed(new_cloudiness)
signal wind_speed_changed(new_wind_speed)
signal wind_direction_changed(new_wind_direction)
signal unshaded_changed(new_is_unshaded)
signal rain_density_changed(new_rain_density)
signal rain_drop_size_changed(new_rain_density)
signal rain_enabled_changed(enabled)

# 0..100 = "clear visibility".."strong haziness"
var visibility = 0 :
	get:
		return visibility # TODOConverter40 Non existent get function 
	set(new_visibility):
		visibility = new_visibility
		emit_signal("visibility_changed", visibility)

# 0..100 = "clear sky".."fully overcast"
var cloudiness = 0 :
	get:
		return cloudiness # TODOConverter40 Non existent get function 
	set(new_cloudiness):
		cloudiness = new_cloudiness
		emit_signal("cloudiness_changed", cloudiness)

# in km/h
var wind_speed = 10 :
	get:
		return wind_speed # TODOConverter40 Non existent get function 
	set(new_wind_speed):
		wind_speed = new_wind_speed
		emit_signal("wind_speed_changed", wind_speed)

# in degrees
var wind_direction = 0 :
	get:
		return wind_direction # TODOConverter40 Non existent get function 
	set(new_wind_direction):
		wind_direction = new_wind_direction
		emit_signal("wind_direction_changed", wind_direction)

var rain_enabled := false :
	get:
		return rain_enabled # TODOConverter40 Non existent get function 
	set(enabled):
		rain_enabled = enabled 
		emit_signal("rain_enabled_changed", enabled)

var rain_density := 100.0 :
	get:
		return rain_density # TODOConverter40 Non existent get function 
	set(new_rain_density):
		rain_density = new_rain_density 
		emit_signal("rain_density_changed", rain_density)

var rain_drop_size := Vector2(0.5, 0.25) :
	get:
		return rain_drop_size # TODOConverter40 Non existent get function 
	set(new_rain_drop_size):
		rain_drop_size = new_rain_drop_size
		emit_signal("rain_drop_size_changed", new_rain_drop_size)

var is_unshaded := false :
	get:
		return is_unshaded # true or false; makes objects completely unshaded
	set(new_is_unshaded):
		is_unshaded = new_is_unshaded
		emit_signal("unshaded_changed", is_unshaded)
