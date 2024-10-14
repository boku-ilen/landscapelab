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


static var weather_presets := {
	"Clear": {
		"visibility": 3,
		"cloud_coverage": 8,
		"cloud_density": 15,
		"wind_speed": 5,
		"rain_enabled": false,
		"lightning_frequency": 0
	},
	"Few Clouds": {
		"visibility": 10,
		"cloud_coverage": 15,
		"cloud_density": 50,
		"wind_speed": 35,
		"rain_enabled": false,
		"lightning_frequency": 0
	},
	"Overcast": {
		"visibility": 35,
		"cloud_coverage": 45,
		"cloud_density": 25,
		"wind_speed": 20,
		"rain_enabled": false,
		"lightning_frequency": 0
	},
	"Drizzle Rain": {
		"visibility": 35,
		"cloud_coverage": 45,
		"cloud_density": 50,
		"wind_speed": 5,
		"rain_enabled": true,
		"rain_density": 3.5,
		"rain_size": 0.015,
		"lightning_frequency": 0
	},
	"Heavy Rain": {
		"visibility": 45,
		"cloud_coverage": 75,
		"cloud_density": 35,
		"wind_speed": 15,
		"rain_enabled": true,
		"rain_density": 7.5,
		"rain_size": 0.05,
		"lightning_frequency": 0
	},
	"Gusts": {
		"visibility": 10,
		"cloud_coverage": 15,
		"cloud_density": 20,
		"wind_speed": 80,
		"rain_enabled": false,
		"lightning_frequency": 0
	},
	"Thunderstorm": {
		"visibility": 80,
		"cloud_coverage": 80,
		"cloud_density": 50,
		"wind_speed": 50,
		"rain_enabled": true,
		"rain_density": 7.5,
		"rain_size": 0.04,
		"lightning_frequency": 75
	},
	"Foggy": {
		"visibility": 100,
		"cloud_coverage": 70,
		"cloud_density": 40,
		"wind_speed": 0,
		"rain_enabled": false,
		"lightning_frequency": 0
	}
}


func activate_weather(config_name):
	for attribute_name in weather_presets[config_name].keys():
		weather_manager.set(attribute_name, weather_presets[config_name][attribute_name])


func activate_time(config_name):
	time_manager.set_datetime_by_dict(time_presets[config_name])


func apply_current_values():
	$LiveWeatherService.apply_current_weather()
	time_manager.set_datetime_by_dict(Time.get_datetime_dict_from_system(true))
