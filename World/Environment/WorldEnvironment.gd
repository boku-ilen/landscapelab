extends WorldEnvironment

@onready var light = get_node("DirectionalLight3D")

var wind_speed = 0
var wind_direction = 0

var brightest_light_energy = 0.75
var light_darken_begin_altitude = 15.0
var light_disabled_altitude = 3.0


func apply_visibility(new_visibility):
	environment.fog_density = new_visibility * 0.000008


func apply_rain_enabled(enabled: bool):
	$Rain.enabled = enabled


func apply_rain_drop_size(rain_drop_size: float):
	$Rain.drop_size = rain_drop_size


func apply_rain_density(rain_density: float):
	$Rain.density = rain_density


func apply_cloudiness(new_cloudiness):
	environment.sky.get_material().set_shader_parameter("cloud_coverage", new_cloudiness * 0.01)
	
	apply_light_energy()


func apply_wind_speed(new_wind_speed):
	wind_speed = new_wind_speed
	apply_wind()


func apply_wind_direction(new_wind_direction):
	wind_direction = new_wind_direction
	apply_wind()


func apply_wind():
	var rotated_vector = Vector2.UP.rotated(deg_to_rad(wind_direction))
	# FIXME: apply wind speed to clouds
#	$CloudDome.cloud_speed = wind_vector
	$Rain.wind_direction = Vector3(rotated_vector.x, -1, rotated_vector.y)
	$Rain.wind_speed = wind_speed


func apply_datetime(datetime: Dictionary):
	# TODO: Replace with real lon/lat values
	var angles = SunPosition.get_solar_angles_for_datetime(datetime, 48.0, 15.0)
	
	light.rotation = Vector3(-angles["altitude"], PI - angles["azimuth"], 0)
	
	apply_light_energy()


func apply_light_energy():
	var altitude = rad_to_deg(-light.rotation.x)
	
	# Light energy is halved when it is maximally cloudy
	var brightest = brightest_light_energy - environment.sky.get_material().get_shader_parameter("cloud_coverage") * 0.000025
	
	if altitude > light_disabled_altitude and altitude < light_darken_begin_altitude:
		_set_light_energy(inverse_lerp(light_disabled_altitude, light_darken_begin_altitude, altitude) * brightest)
	elif altitude <= light_disabled_altitude:
		_set_light_energy(0.0)
	else:
		_set_light_energy(brightest)


func _set_light_energy(new_energy):
	light.light_energy = new_energy
