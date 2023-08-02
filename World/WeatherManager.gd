extends Node
class_name WeatherManager


signal visibility_changed(new_visibility)
signal cloudiness_changed(new_cloudiness)
signal wind_speed_changed(new_wind_speed)
signal wind_direction_changed(new_wind_direction)
signal rain_density_changed(new_rain_density)
signal rain_drop_size_changed(new_rain_density)
signal rain_enabled_changed(enabled)

# 0..100 = "clear visibility".."strong haziness"
var visibility = 0 :
	get:
		return visibility
	set(new_visibility):
		visibility = new_visibility
		visibility_changed.emit(visibility)

# 0..100 = "clear sky".."fully overcast"
var cloudiness = 0 :
	get:
		return cloudiness
	set(new_cloudiness):
		cloudiness = new_cloudiness
		cloudiness_changed.emit(cloudiness)

# in km/h
var wind_speed = 10 :
	get:
		return wind_speed
	set(new_wind_speed):
		wind_speed = new_wind_speed
		wind_speed_changed.emit(wind_speed)

# in degrees
var wind_direction = 0 :
	get:
		return wind_direction
	set(new_wind_direction):
		wind_direction = new_wind_direction
		wind_direction_changed.emit(wind_direction)

var rain_enabled := false :
	get:
		return rain_enabled
	set(enabled):
		rain_enabled = enabled 
		rain_enabled_changed.emit(enabled)

var rain_density := 100.0 :
	get:
		return rain_density
	set(new_rain_density):
		rain_density = new_rain_density 
		rain_density_changed.emit(rain_density)

var rain_drop_size := 0.5 :
	get:
		return rain_drop_size
	set(new_rain_drop_size):
		rain_drop_size = new_rain_drop_size
		rain_drop_size_changed.emit(new_rain_drop_size)
