extends WorldEnvironment

# Diffuse and specular
@onready var light: DirectionalLight3D = get_node("DirectionalLight")
# Ambient and sky
@onready var sky_light: DirectionalLight3D = get_node("DirectionalLight/SkyLight")

var wind_speed = 0
var wind_direction = 0

var brightest_light_energy = 1.5
var light_darken_begin_altitude = 15.0
var light_disabled_altitude = 3.0


func apply_visibility(new_visibility):
	environment.fog_density = remap(new_visibility, 0., 100., 0, 0.00015)
	# Enable volumetric fog only above a certain threshold
	environment.volumetric_fog_density = remap(new_visibility, 30., 100., 0.0, 0.045)


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
	# Directional light energy is 0 when cloud coverage is maximized
	var cloud_coverage = environment.sky.get_material().get_shader_parameter("cloud_coverage")
	var directional_energy = brightest_light_energy - remap(cloud_coverage, 0, 1, 0, brightest_light_energy)
	
	# Lower light quickly in the beginning when coverage/density are higher
	# and lower light slower in the end (sqrt-curve-function), vice versa for ssao
	var sqrt_cloud_cov = sqrt(cloud_coverage)
	sky_light.light_energy = 4.0 - remap(sqrt_cloud_cov, 0, 1, 0, 2)
	environment.ssao_intensity = 3.0 + remap(sqrt_cloud_cov, 0, 1, 0, 5)
	
	var altitude = rad_to_deg(-light.rotation.x)
	# Sunrise/sunset
	if altitude > light_disabled_altitude and altitude < light_darken_begin_altitude:
		_set_directional_light_energy(directional_energy * 
			inverse_lerp(light_disabled_altitude, light_darken_begin_altitude, altitude))
	# Night
	elif altitude <= light_disabled_altitude:
		_set_directional_light_energy(0.0)
	else:
		_set_directional_light_energy(directional_energy)


func _set_directional_light_energy(new_energy):
	light.light_energy = new_energy


func set_lightning_enabled(enabled: bool):
	$Lightning.enabled = enabled


func set_lightning_rotation(rotation_deg: float):
	$Lightning.rot_degrees = rotation_deg
