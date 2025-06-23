extends WorldEnvironment

# Diffuse and specular
@onready var light: DirectionalLight3D = get_node("SkyLight/WorldLight")
# Ambient and sky
@onready var sky_light: DirectionalLight3D = get_node("SkyLight")

var wind_speed = 0
var wind_direction = 0

var brightest_light_energy = 4.0
var light_darken_begin_altitude = 15.0
var light_disabled_altitude = 0.0


var current_target_light_rotation: Vector3
var current_target_light_energy: float


func _physics_process(delta: float) -> void:
	sky_light.rotation = lerp(sky_light.rotation, current_target_light_rotation, 0.01)
	apply_light_energy()


func apply_visibility(new_visibility):
	environment.fog_density = remap(new_visibility, 0., 100., 0.00004, 0.001)
	
	# Enable volumetric fog only above a certain threshold
	environment.volumetric_fog_enabled = new_visibility > 70
	environment.volumetric_fog_density = remap(new_visibility, 70., 100., 0.000, 0.045)
	
	const blue_color = Color("#0830a6")
	const gray_color = Color("#426994")
	var new_color = Color.from_hsv(
		lerp(blue_color.h, gray_color.h, new_visibility / 100.0),
		lerp(blue_color.s, gray_color.s, new_visibility / 100.0),
		lerp(blue_color.v, gray_color.v, new_visibility / 100.0)
	)
	# FIXME: how to set with new sky?
	#environment.sky.get_material().set_shader_parameter("rayleigh_color", new_color)


func apply_rain_enabled(enabled: bool):
	$Rain.enabled = enabled


func apply_rain_drop_size(rain_drop_size: float):
	$Rain.drop_size = rain_drop_size


func apply_rain_density(rain_density: float):
	$Rain.density = rain_density


func apply_cloud_coverage(new_cloudiness):
	environment.sky.cloud_coverage = new_cloudiness * 0.01
	
	apply_light_energy()


func apply_cloud_density(new_density):
	environment.sky.density = remap(new_density, 0, 100, 0.0, 0.3)
	
	apply_light_energy()


func apply_wind_speed(new_wind_speed):
	wind_speed = new_wind_speed
	apply_wind()


func apply_wind_direction(new_wind_direction):
	wind_direction = new_wind_direction
	apply_wind()


func apply_wind():
	var rotated_vector = Vector2.UP.rotated(deg_to_rad(wind_direction))
	
	environment.sky.wind_speed = wind_speed * 0.2
	environment.sky.wind_direction = -rotated_vector
	$Rain.wind_direction = Vector3(rotated_vector.x, -1, rotated_vector.y)
	$Rain.wind_speed = wind_speed


func apply_datetime(datetime: Dictionary):
	# TODO: Replace with real lon/lat values
	var angles = SunPosition.get_solar_angles_for_datetime(datetime, 48.0, 15.0)
	
	current_target_light_rotation = Vector3(-angles["altitude"], PI - angles["azimuth"], 0)


func apply_light_energy():
	# Directional light energy is 0 when cloud coverage is maximized
	var cloud_coverage = environment.sky.cloud_coverage
	var directional_energy = brightest_light_energy - remap(cloud_coverage, 0, 1, 0, brightest_light_energy * 0.8)
	
	# Lower light quickly in the beginning when coverage/density are higher
	# and lower light slower in the end (sqrt-curve-function), vice versa for ssao
	var sqrt_cloud_cov = sqrt(cloud_coverage)
	environment.background_energy_multiplier = 3.0 - sqrt_cloud_cov
	environment.ssao_intensity = 3.0 + remap(sqrt_cloud_cov, 0, 1, 0, 5)
	
	var altitude = rad_to_deg(-sky_light.rotation.x)
	
	# Light is more intensely yellow in the morning and evening
	light.light_color.s = clamp(remap(abs(altitude), 5.0, 35.0, 0.4, 0.05), 0.05, 0.4)
	
	# Sunrise/sunset
	if altitude < light_darken_begin_altitude:
		environment.ambient_light_energy = inverse_lerp(light_disabled_altitude, light_darken_begin_altitude, altitude)
		_set_directional_light_energy(directional_energy * 
			inverse_lerp(light_disabled_altitude, light_darken_begin_altitude, altitude))
	else:
		_set_directional_light_energy(directional_energy)
		environment.ambient_light_energy = 1.0 + remap(cloud_coverage, 0, 1, 0.0, 0.5)


func _set_directional_light_energy(new_energy):
	light.light_energy = new_energy
	light.shadow_blur = 8.0 - (new_energy / brightest_light_energy) * 6.0
	light.shadow_opacity = 0.4 + (new_energy / brightest_light_energy) * 0.4


func set_lightning_frequency(frequency: float):
	$Lightning.frequency = frequency


func set_lightning_orientation(rotation_deg: float):
	$Lightning.orientation = rotation_deg
