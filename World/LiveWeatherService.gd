extends Node

@export var weather_manager: WeatherManager
@export var player: AbstractPlayer


func apply_current_weather():
	# OpenMeteo API
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_http_request_completed)
	
	var position = player.get_lat_lon()

	# Perform a GET request. The URL below returns JSON as of writing.
	# FIXME: use real lat/lon from player position
	var error = http_request.request("https://api.open-meteo.com/v1/forecast?latitude=%f&longitude=%f&current=temperature_2m,relative_humidity_2m,rain,showers,snowfall,cloud_cover,wind_speed_10m,wind_direction_10m"
			% [position.z, position.x])
	if error != OK:
		push_error("An error occurred in the HTTP request.")


# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	logger.info(str(response))
	
	var temperature = response["current"]["temperature_2m"]
	var humidity = response["current"]["relative_humidity_2m"]
	var rain = response["current"]["rain"]
	var showers = response["current"]["showers"]
	var snowfall = response["current"]["snowfall"]
	var cloud_cover = response["current"]["cloud_cover"]
	var wind_speed = response["current"]["wind_speed_10m"]
	var wind_direction = response["current"]["wind_direction_10m"]
	
	weather_manager.wind_speed = wind_speed
	weather_manager.wind_direction = wind_direction
	weather_manager.cloud_coverage = pow(cloud_cover / 100.0, 1.75) * 100.0 # Scale to make percentage work as intended
	
	if rain > 0:
		weather_manager.cloud_density = 66.0
	elif showers > 0:
		weather_manager.cloud_density = 33.0
	else:
		weather_manager.cloud_density = 0.0
