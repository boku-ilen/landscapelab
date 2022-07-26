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

var visibility = 0 setget set_visibility # 0..100 = "clear visibility".."strong haziness"
var cloudiness = 0 setget set_cloudiness # 0..100 = "clear sky".."fully overcast"
var wind_speed = 10 setget set_wind_speed # in km/h
var wind_direction = 0 setget set_wind_direction # in degrees
var rain_enabled := false setget set_rain_enabled
var rain_density := 100.0 setget set_rain_density
var rain_drop_size := 1.0 setget set_rain_drop_size
var is_unshaded = false setget set_is_unshaded # true or false; makes objects completely unshaded


func _ready():
	var remote_transform = RemoteTransform.new()
	remote_transform.remote_path = get_parent().get_node("WorldEnvironment/Rain").get_path()
	get_parent().get_node("FirstPersonPC").add_child(remote_transform)


func set_visibility(new_visibility):
	visibility = new_visibility
	emit_signal("visibility_changed", visibility)


func set_rain_enabled(enabled: bool):
	rain_enabled = enabled 
	emit_signal("rain_enabled_changed", enabled)


func set_rain_density(new_rain_density: float):
	rain_density = new_rain_density 
	emit_signal("rain_density_changed", rain_density)


func set_rain_drop_size(new_rain_drop_size: float):
	rain_drop_size = new_rain_drop_size
	emit_signal("rain_drop_size_changed", new_rain_drop_size)


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
