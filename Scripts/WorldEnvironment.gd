tool
extends WorldEnvironment

var server = global.server
var port = global.port

onready var light = get_node("DirectionalLight")

var current_time = 0
var current_season = 0

var base_horizon_color = Color(142.0 / 255.0, 209.0 / 255.0, 232.0 / 255.0, 1.0) # Godot's default values - they look pretty good
var base_top_color = Color(12.0 / 255.0, 116.0 / 255.0, 249.0 / 255.0, 1)

var sun_change_thread = Thread.new()

func get_middle_of_season(season): # 0 = winter, 1 = spring, 2 = summer, 3 = fall
	return {day = 1, month = 2 + season * 3, year = 2018}
	# Example: Spring -> 1.5.2018
	
func set_sun_position_for_seasontime(season, hours):
	print("setting pos")
	var date = get_middle_of_season(season)
	set_sun_position_for_datetime(hours, date.day, date.month, date.year)
	
func set_sun_position_for_datetime(hours, day, month, year):
	# Placeholder values
	var position_longitude = 15.1
	var position_latitude = 48.1
	var elevation = 100.1
	
	var url = "/location/sunposition/%04d/%02d/%02d/%02d/%02d/%f/%f/%f.json" % [year, month, day, floor(hours), floor((hours - floor(hours)) * 60), position_longitude, position_latitude, elevation]
	
	var result = ServerConnection.getJson(server, url, port)
	
	set_sun_position(result.altitude, result.azimuth)

func set_sun_position(altitude, azimuth):
	# Godot calls the values latitude and longitude for some reason, but they are actually equivalent to altitude and azimuth
	environment.background_sky.sun_latitude = altitude
	
	# Longitude must be between -180 and 180
	if azimuth > 180: azimuth -= 360
	environment.background_sky.sun_longitude = azimuth
	
	# Change the directional light to reflect sun change
	light.rotation_degrees = Vector3(-altitude, 180 - azimuth, 0)
	
	update_colors(altitude, azimuth)
	
func update_colors(altitude, azimuth):
	var new_horizon_color = base_horizon_color
	var new_top_color = base_top_color
	
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
		
	elif altitude <= -30:
		new_top_color = Color(0, 0, 0, 0)
	
	# Apply the colors to the sky
	environment.background_sky.ground_horizon_color = new_horizon_color
	environment.background_sky.sky_horizon_color = new_horizon_color
	environment.background_sky.sky_top_color = new_top_color

func _ready():
	# React to time_changed events
	GlobalSignal.connect("time_changed", self, "_on_time_changed")
	GlobalSignal.connect("season_changed", self, "_on_season_changed")
	
	# Set time and season with default values
	update_time_season()
	
func _on_time_changed(time):
	current_time = time
	update_time_season()
	
func _on_season_changed(season):
	current_season = season
	update_time_season()
	
func update_time_season():
	# Run this in a thread to prevent stutter while waiting for HTTP request
	
	if sun_change_thread.is_active():
		logger.warning("Attempt to change time/season, but last change hasn't finished - aborting")
		return
	
	sun_change_thread.start(self, "_bg_set_sun_position_for_seasontime", [current_season, current_time])
	
func _bg_set_sun_position_for_seasontime(data): # Threads can only take one argument, so we need this helper function
	set_sun_position_for_seasontime(data[0], data[1])
	call_deferred("end_thread")
	
func end_thread():
	sun_change_thread.wait_to_finish()
