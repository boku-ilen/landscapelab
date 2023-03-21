extends WorldEnvironment

@onready var light = get_node("DirectionalLight3D")

var wind_speed = 0
var wind_direction = 0


func apply_visibility(new_visibility):
	environment.fog_density = new_visibility * 0.0001


func apply_rain_enabled(enabled):
	$RainParticles.emitting = enabled


func apply_rain_drop_size(rain_drop_size):
	$RainParticles.scale_x = rain_drop_size.x
	$RainParticles.scale_y = rain_drop_size.y


func apply_rain_density(rain_density):
	$RainParticles.amount = rain_density


func apply_cloudiness(new_cloudiness):
	environment.sky.get_material().set_shader_parameter("cloud_coverage", new_cloudiness * 0.01)


func apply_wind_speed(new_wind_speed):
	wind_speed = new_wind_speed
	apply_wind()


func apply_wind_direction(new_wind_direction):
	wind_direction = new_wind_direction
	apply_wind()


func apply_wind():
	var rotated_vector = Vector2.UP.rotated(deg_to_rad(wind_direction))
	#var wind_vector = rotated_vector * wind_speed * 5.0
#	$CloudDome.cloud_speed = wind_vector
	# FIXME: the angle should also be applied - it rotates with the camera however
	# $Rain.process_material.angle = 
	$RainParticles.wind_force_east = rotated_vector.x * wind_speed * 0.3
	$RainParticles.wind_force_north = rotated_vector.y * wind_speed  * 0.3


func apply_datetime(datetime: Dictionary):
	# TODO: Replace with real lon/lat values
	var angles = SunPosition.get_solar_angles_for_datetime(datetime, 48.0, 15.0)
	
	light.rotation = Vector3(-angles["altitude"], PI - angles["azimuth"], 0)
	
	if angles["altitude"] < 0.0:
		set_light_energy(0.0)
	else:
		set_light_energy(1.0)


func set_light_energy(new_energy):
	light.light_energy = new_energy
