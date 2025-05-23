extends GridContainer


var weather_manager: WeatherManager : 
	set(manager):
		weather_manager = manager
		$LiveWeather/LiveWeatherButton/LiveWeatherService.weather_manager = weather_manager
		_on_preconfiguration_selected(0)


func _resort_children():
	columns = 2
	var children_index = 0
	for child in get_children():
		for subchild in child.get_children():
			if subchild.name == "Label":
				subchild.reparent(self)
				move_child(subchild, children_index)
				children_index += 1
		children_index += 1


func _ready():
	_resort_children()
	
	# Connect weather option signals with weather_manager
	$Visibility/HSlider.value_changed.connect(func(value): 
		weather_manager.visibility = value)
	$CloudCoverage/HSlider.value_changed.connect(func(value):
		weather_manager.cloud_coverage = value)
	$CloudDensity.value_changed.connect(func(value):
		weather_manager.cloud_density = value)
	$WindSpeed/HSlider.value_changed.connect(func(value):
		weather_manager.wind_speed = value)
	$WindDirection/HSlider.value_changed.connect(func(value):
		weather_manager.wind_direction = value)
	$Rain/CheckBox.toggled.connect(func(value):
		weather_manager.rain_enabled = value)
	$RainDensity/HSlider.value_changed.connect(func(value):
		weather_manager.rain_density = value)
	$RainDropSize.value_changed.connect(func(value):
		weather_manager.rain_drop_size = value)
	$LightningFrequency.value_changed.connect(func(value):
		weather_manager.lightning_frequency = value)
	$LightningOrientation.value_changed.connect(func(value): 
		weather_manager.lightning_orientation = value)
	
	# Add/apply preconfigurated weather categories and connect signals
	_add_preconfigured_options()
	$Preconfigurations/OptionButton.item_selected.connect(_on_preconfiguration_selected)


func _add_preconfigured_options():
	var idx := 0
	for label in preconfigurations.keys():
		$Preconfigurations/OptionButton.add_item(label)
		$Preconfigurations/OptionButton.set_item_metadata(idx, preconfigurations[label])
		idx += 1


func _on_preconfiguration_selected(idx):
	var configuration = $Preconfigurations/OptionButton.get_item_metadata(idx)
	for access_str in configuration.keys():
		var node_path = access_str.split(":")[0]
		var property = access_str.split(":")[1]
		get_node(node_path).set(property, configuration[access_str])


# Access the wished UI property via node_path:property
var haziness = "Visibility/HSlider:value"
var cloud_coverage = "CloudCoverage/HSlider:value"
var cloud_density = "CloudDensity:value"
var wind_speed = "WindSpeed/HSlider:value"
var rain_enabled = "Rain/CheckBox:button_pressed"
var rain_density = "RainDensity:value"
var rain_size = "RainDropSize:value"
var lightning_frequency = "LightningFrequency:value"

# Preconfigured weather categories
var preconfigurations := {
	"Clear Sky": {
		haziness: 8,
		cloud_coverage: 8,
		cloud_density: 15,
		wind_speed: 5,
		rain_enabled: false,
		lightning_frequency: 0
	},
	"Few Clouds": {
		haziness: 16,
		cloud_coverage: 15,
		cloud_density: 50,
		wind_speed: 15,
		rain_enabled: false,
		lightning_frequency: 0
	},
	"Overcast": {
		haziness: 22,
		cloud_coverage: 45,
		cloud_density: 25,
		wind_speed: 20,
		rain_enabled: false,
		lightning_frequency: 0
	},
	"Drizzle Rain": {
		haziness: 35,
		cloud_coverage: 45,
		cloud_density: 50,
		wind_speed: 5,
		rain_enabled: true,
		rain_density: 3.5,
		rain_size: 0.015,
		lightning_frequency: 0
	},
	"Heavy Rain": {
		haziness: 45,
		cloud_coverage: 75,
		cloud_density: 35,
		wind_speed: 15,
		rain_enabled: true,
		rain_density: 7.5,
		rain_size: 0.05,
		lightning_frequency: 0
	},
	"Gusts": {
		haziness: 10,
		cloud_coverage: 15,
		cloud_density: 20,
		wind_speed: 80,
		rain_enabled: false,
		lightning_frequency: 0
	},
	"Thunderstorm": {
		haziness: 80,
		cloud_coverage: 80,
		cloud_density: 50,
		wind_speed: 50,
		rain_enabled: true,
		rain_density: 7.5,
		rain_size: 0.04,
		lightning_frequency: 75
	},
	"Foggy": {
		haziness: 100,
		cloud_coverage: 70,
		cloud_density: 40,
		wind_speed: 0,
		rain_enabled: false,
		lightning_frequency: 0
	}
}
