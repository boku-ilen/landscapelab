extends WorldEnvironment

@onready var light: DirectionalLight3D = get_node("WorldLight")

var wind_speed = 0
var wind_direction = 0

var brightest_light_energy = 4.0
var light_darken_begin_altitude = 15.0
var light_disabled_altitude = 0.0


var current_target_light_rotation: Vector3
var current_target_light_energy: float


func _physics_process(delta: float) -> void:
	light.rotation = lerp(light.rotation, current_target_light_rotation, 0.01)
	apply_light_energy()


func apply_visibility(new_visibility):
	environment.fog_density = remap(pow(new_visibility / 10.0, 2.0), 0., 100., 0.00004, 0.004)
	environment.fog_sky_affect = min(remap(new_visibility, 0., 70., 0.0, 1.0), 1.0)
	environment.fog_aerial_perspective = max(remap(new_visibility, 0., 70., 1.0, 0.0), 0.01)


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
	
	var new_light_intensity = lerp(120000, 0, cloud_coverage)
	var new_light_temperature = lerp(5000, 6000, cloud_coverage)
	
	# Lower light quickly in the beginning when coverage/density are higher
	# and lower light slower in the end (sqrt-curve-function), vice versa for ssao
	var sqrt_cloud_cov = sqrt(cloud_coverage)
	environment.ssao_intensity = 3.0 + remap(sqrt_cloud_cov, 0, 1, 0, 5)
	
	var altitude = rad_to_deg(-light.rotation.x)
	var altitude_factor = smoothstep(light_disabled_altitude, light_darken_begin_altitude, altitude)
	
	# Light is more intensely yellow in the morning and evening
	#light.light_color.s = clamp(remap(abs(altitude), 5.0, 35.0, 0.4, 0.05), 0.05, 0.4)
	
	# Sunrise/sunset
	if altitude < light_darken_begin_altitude:
		environment.ambient_light_energy = altitude_factor
		new_light_intensity *= inverse_lerp(light_disabled_altitude, light_darken_begin_altitude, altitude)
		
		new_light_temperature = lerp(1850.0, new_light_temperature, altitude_factor)
	else:
		environment.ambient_light_energy = 1.0 + remap(cloud_coverage, 0, 1, 0.0, 0.5)
	
	# Clamp to 0.0
	new_light_intensity = max(new_light_intensity, 0.0)
	
	light.light_intensity_lux = new_light_intensity
	light.light_temperature = new_light_temperature
	
	environment.fog_light_energy = altitude_factor
	environment.background_energy_multiplier = altitude_factor


func _set_directional_light_energy(new_energy):
	light.light_energy = new_energy
	light.shadow_blur = 8.0 - (new_energy / brightest_light_energy) * 6.0
	light.shadow_opacity = 0.4 + (new_energy / brightest_light_energy) * 0.4


func set_lightning_frequency(frequency: float):
	$Lightning.frequency = frequency


func set_lightning_orientation(rotation_deg: float):
	$Lightning.orientation = rotation_deg
