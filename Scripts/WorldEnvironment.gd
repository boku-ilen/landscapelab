tool
extends WorldEnvironment

export var server = "http://127.0.0.1"
export var port = 8000

onready var light = get_node("DirectionalLight")

var current_time = 0
var current_season = 0

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
	
	# TODO: Kill old thread on new request
	var sun_change_thread = Thread.new()
	sun_change_thread.start(self, "_bg_set_sun_position_for_seasontime", [current_season, current_time])
	
func _bg_set_sun_position_for_seasontime(data): # Threads can only take one argument, so we need this helper function
	set_sun_position_for_seasontime(data[0], data[1])
