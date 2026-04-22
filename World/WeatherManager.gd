extends Node
class_name WeatherManager


signal visibility_changed(new_visibility)
signal cloud_coverage_changed(new_cloudiness)
signal cloud_density_changed(new_density)
signal wind_speed_changed(new_wind_speed)
signal wind_direction_changed(new_wind_direction)
signal rain_density_changed(new_rain_density)
signal rain_drop_size_changed(new_rain_density)
signal rain_enabled_changed(enabled)
signal lightning_frequency_changed(frequency)
signal lightning_orientation_changed(rotation_degrees)

# 0..100 = "clear visibility".."strong haziness"
var visibility = 0 :
	get:
		return visibility
	set(new_visibility):
		visibility = new_visibility
		visibility_changed.emit(visibility)

# 0..100 = "clear sky".."fully overcast"
var cloud_coverage = 0 :
	get:
		return cloud_coverage
	set(coverage):
		cloud_coverage = coverage
		cloud_coverage_changed.emit(cloud_coverage)

# 0..100 = "white clouds".."black clouds"
var cloud_density = 0 :
	get:
		return cloud_density
	set(density):
		cloud_density = density
		cloud_density_changed.emit(cloud_density)

# in km/h
var wind_speed = 10 :
	get:
		return wind_speed
	set(new_wind_speed):
		wind_speed = new_wind_speed
		wind_speed_changed.emit(wind_speed)

# in degrees
var wind_direction = 0 :
	get:
		return wind_direction
	set(new_wind_direction):
		wind_direction = new_wind_direction
		wind_direction_changed.emit(wind_direction)

var rain_enabled := false :
	get:
		return rain_enabled
	set(enabled):
		rain_enabled = enabled 
		rain_enabled_changed.emit(enabled)

var rain_density := 1 :
	get:
		return rain_density
	set(new_rain_density):
		rain_density = new_rain_density 
		rain_density_changed.emit(rain_density)

var rain_drop_size := 0.1 :
	get:
		return rain_drop_size
	set(new_rain_drop_size):
		rain_drop_size = new_rain_drop_size
		rain_drop_size_changed.emit(new_rain_drop_size)

var lightning_frequency := 0.0 :
	get:
		return lightning_frequency
	set(frequency):
		lightning_frequency = frequency
		lightning_frequency_changed.emit(lightning_frequency)


# Orientation of lightning center relative to the center_node position in degrees
var lightning_orientation := 0 :
	set(new_orientation):
		lightning_orientation = new_orientation
		lightning_orientation_changed.emit(lightning_orientation)


static var presets := {
	"Clear": {
		"visibility": 10,
		"cloud_coverage": 8,
		"cloud_density": 15,
		"wind_speed": 5,
		"rain_enabled": false,
		"lightning_frequency": 0
	},
	"Few Clouds": {
		"visibility": 20,
		"cloud_coverage": 15,
		"cloud_density": 50,
		"wind_speed": 35,
		"rain_enabled": false,
		"lightning_frequency": 0
	},
	"Overcast": {
		"visibility": 30,
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


@export var default_preset: String = "Few Clouds"


func activate_preset(preset_name: String):
	for attribute_name in presets[preset_name].keys():
		set(attribute_name,  presets[preset_name][attribute_name])


func _ready():
	# Wait for everything else to be ready
	await get_tree().process_frame
	activate_preset(default_preset)
