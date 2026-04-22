extends Node
class_name AtmosphereConfiguration


var weather_manager: WeatherManager
var time_manager: TimeManager


static var time_presets := {
	"Sunrise": {
		"day": 16,
		"month": 4,
		"year": 2024,
		"hour": 6.0,
		"minute": 0.0,
		"second": 0.0
	},
	"Noon": {
		"day": 16,
		"month": 4,
		"year": 2024,
		"hour": 11.0,
		"minute": 0.0,
		"second": 0.0
	},
	"Sunset": {
		"day": 16,
		"month": 4,
		"year": 2024,
		"hour": 16.0,
		"minute": 30.0,
		"second": 0.0
	},
	"Night": {
		"day": 16,
		"month": 4,
		"year": 2024,
		"hour": 23.0,
		"minute": 0.0,
		"second": 0.0
	}
}


func activate_weather(config_name):
	weather_manager.activate_preset(config_name)


func activate_time(config_name):
	time_manager.set_datetime_by_dict(time_presets[config_name])


func apply_current_values():
	$LiveWeatherService.apply_current_weather()
	time_manager.set_datetime_by_dict(Time.get_datetime_dict_from_system(true))
