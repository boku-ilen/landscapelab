extends WorldEnvironment

onready var light = get_node("DirectionalLight")

const LOG_MODULE := "WORLDENV"

var FOG_BEGIN = Settings.get_setting("sky", "fog-begin")
var FOG_END = Settings.get_setting("sky", "fog-end")
var MAX_SUN_INTENSITY = Settings.get_setting("sky", "max-sun-intensity")

var clouds

var current_time = 12
var current_season = 0

var wind_speed = 0
var wind_direction = 0

# Godot's default values - they look pretty good
var base_horizon_color = Color(139.0 / 255.0, 175.0 / 255.0, 207.0 / 255.0, 1.0) 
var base_top_color = Color(54.0 / 255.0, 80.0 / 255.0, 141.0 / 255.0, 1)

var sun_change_thread = Thread.new()

func _on_Sky_texture_sky_updated():
	$Sky_texture.copy_to_environment(environment)


func _ready():
	$Sky_texture.connect("sky_updated", self, "_on_Sky_texture_sky_updated")
	$Sky_texture.set_time_of_day(7.0, get_node("DirectionalLight"), self, deg2rad(10.0), 1.5)
	
	environment.fog_depth_begin = FOG_BEGIN
	environment.fog_depth_end = FOG_END


func apply_visibility(new_visibility):
	environment.fog_depth_begin = (100 - new_visibility) * 100 + 500
	environment.fog_depth_end = (100 - new_visibility) * 300 + 1500


func apply_cloudiness(new_cloudiness):
	$CloudDome.cloud_min_density_low = 1.1 - new_cloudiness * 0.01
	
	# TODO: Consider decreasing light.light_energy and increasing the ambient light instead


func apply_wind_speed(new_wind_speed):
	wind_speed = new_wind_speed
	apply_wind()


func apply_wind_direction(new_wind_direction):
	wind_direction = new_wind_direction
	apply_wind()


func apply_wind():
	var rotated_vector = Vector2.UP.rotated(deg2rad(wind_direction))
	$CloudDome.cloud_speed = rotated_vector * wind_speed * 5.0


func apply_is_unshaded(new_is_unshaded):
	# TODO: Implement
	pass


func apply_datetime(date_time: TimeManager.DateTime):
	if $PythonWrapper.has_python_node():
		# TODO: Replace with real lon/lat values
		var altitude_azimuth = $PythonWrapper.get_python_node().get_sun_altitude_azimuth(
			48.0, 15.0, date_time.time, date_time.day, date_time.year)
		
		$Sky_texture.set_sun_altitude_azimuth(altitude_azimuth[0], altitude_azimuth[1],
				get_node("DirectionalLight"), self, 1.5)
		
		if altitude_azimuth[0] < 0:
			environment.ambient_light_energy = 0.75
			$DirectionalLight.light_energy = 0
			$CloudDome.cloud_color = Color.white * 0.03 + Color.blue * 0.02
			$CloudDome.shade_color = Color.white * 0.06
			environment.fog_color = Color(0.03, 0.04, 0.05)
			environment.fog_sun_amount = 0
			$CloudDome._regen_mesh()
		else:
			$DirectionalLight.light_energy = 2
			environment.ambient_light_energy = 3
			environment.fog_color = Color(0.501961, 0.6, 0.701961)
			environment.fog_sun_amount = 1
			$CloudDome.cloud_color = Color.white
			$CloudDome.shade_color = Color(0.568627, 0.698039, 0.878431, 1.0)
			$CloudDome._regen_mesh()
	else:
		logger.warn("Pysolar is unavailable, so the sun position is only approximate!", LOG_MODULE)
	
		$Sky_texture.set_time_of_day(date_time.time, get_node("DirectionalLight"), self, deg2rad(10.0), 1.5)


func _physics_process(delta):
	pass
	# Make the light stick to the player in order to always show highest detail shadows next to them
	# FIXME: Make the light follow the player, or just add this scene as a child to the player?
	#light.translation = PlayerInfo.get_engine_player_position()


func get_middle_of_season(season): # 0 = winter, 1 = spring, 2 = summer, 3 = fall
	return {day = 1, month = 2 + season * 3, year = 2018}
	# Example: Spring -> 1.5.2018


func set_sun_position_for_seasontime(season, hours):
	logger.debug("setting sun position to season: %s and time: %s" % [season, hours], LOG_MODULE)
	var date = get_middle_of_season(season)
	set_sun_position_for_datetime(hours, date.day, date.month, date.year)


func set_sun_position_for_datetime(hours, day, month, year):
	# TODO: can we replace these placeholder values with the actual ones?
	var position_longitude = 15.1
	var position_latitude = 48.1
	var elevation = 100.1
	
	# FIXME: pysolar will be included with a direct python call in a subprocess of via godot-python
	# var url = "/location/sunposition/%04d/%02d/%02d/%02d/%02d/%f/%f/%f.json" % [year, month, day, floor(hours), floor((hours - floor(hours)) * 60), position_longitude, position_latitude, elevation]
	set_sun_position(45, 45)


func set_sun_position(altitude, azimuth):
	# Godot calls the values latitude and longitude for some reason, 
	# but they are actually equivalent to altitude and azimuth
	environment.background_sky.sun_latitude = altitude
	
	# Longitude must be between -180 and 180
	if azimuth > 180: azimuth -= 360
	environment.background_sky.sun_longitude = azimuth
	
	# Change the directional light to reflect sun change
	light.rotation_degrees = Vector3(-altitude, 180 - azimuth, 0)
	
	# Also pass the direction as a parameter to the clouds - they require it as 
	# the vector the light is pointing at, which is the forward (-z) vector
	if clouds:
		clouds.set_sun_direction(-light.transform.basis.z)
	
	update_colors(altitude, azimuth)


func set_light_energy(new_energy):
	light.light_energy = new_energy
	#environment.ambient_light_energy = 0.2 + new_energy * 2.2
	
	if clouds:
		clouds.set_sun_energy(new_energy / MAX_SUN_INTENSITY)


func update_colors(altitude, azimuth):
	var new_horizon_color = base_horizon_color
	var new_top_color = base_top_color
	
	var new_light_energy = MAX_SUN_INTENSITY
	
	if altitude < 20 and altitude > -20: # Sun is close to the horizon
		# Make the horizon red/yellow-ish the closer the sun is to the horizon
		var distance_to_horizon = 1 - abs(altitude) / 20
		var horizon_blend_color = Color(0.7, 0.3, 0, distance_to_horizon)
		
		new_horizon_color = new_horizon_color.blend(horizon_blend_color)
		
		# Make the sky get progressively darker
		var distance_to_black_point = 1 - ((20 + altitude) / 40)
		new_horizon_color = new_horizon_color.darkened(distance_to_black_point)
		
	elif altitude <= -20: # Sun is far down -> make the horizon black
		new_horizon_color = Color(0, 0, 0, 0)
	
	# Also make the top color darker / black when the sun is down
	if altitude < 0 and altitude > -30:
		var distance_to_black_point = abs(altitude) / 30
		new_top_color = base_top_color.darkened(distance_to_black_point)
		new_light_energy = MAX_SUN_INTENSITY - distance_to_black_point * MAX_SUN_INTENSITY
		
	elif altitude <= -30:
		new_top_color = Color(0, 0, 0, 0)
		new_light_energy = 0
	
	# Apply the colors to the sky
	environment.background_sky.ground_horizon_color = new_horizon_color
	environment.background_sky.sky_horizon_color = new_horizon_color
	environment.background_sky.sky_top_color = new_top_color
	
	set_light_energy(new_light_energy)


func _on_time_changed(time):
	current_time = time
	update_time_season()


func _on_season_changed(season):
	current_season = season
	update_time_season()


func update_time_season():
	# Run this in a thread to prevent stutter while waiting for HTTP request
	if sun_change_thread.is_active():
		logger.warning("Attempt to change time/season, but last change hasn't finished - aborting", LOG_MODULE)
		return
	
	sun_change_thread.start(self, "_bg_set_sun_position_for_seasontime", [current_season, current_time])
	#_bg_set_sun_position_for_seasontime([current_season, current_time])


func _bg_set_sun_position_for_seasontime(data): # Threads can only take one argument, so we need this helper function
	set_sun_position_for_seasontime(data[0], data[1])
	call_deferred("end_thread")


func end_thread():
	sun_change_thread.wait_to_finish()
