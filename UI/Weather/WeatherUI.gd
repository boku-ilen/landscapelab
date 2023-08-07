extends VBoxContainer


var weather_manager: WeatherManager

func _ready():
	# Connect weather option signals with weather_manager
	$Visibility/HSlider.value_changed.connect(func(value): 
		weather_manager.visibility = value)
	$Clouds/HSlider.value_changed.connect(func(value):
		weather_manager.cloudiness = value)
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
	$Lightning/CheckBox.toggled.connect(func(value):
		weather_manager.lightning_enabled = value)
	$LightningRotation.value_changed.connect(func(value): 
		weather_manager.lightning_rotation = value)
	
	# Add/apply preconfigurated weather categories and connect signals
	_add_preconfigured_options()
	$Preconfigurations/OptionButton.item_selected.connect(_on_preconfiguration_selected)
	$Preconfigurations/OptionButton.select(0)


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
var cloudiness = "Clouds/HSlider:value"
var wind_speed = "WindSpeed/HSlider:value"
var rain_enabled = "Rain/CheckBox:button_pressed"
var rain_density = "RainDensity:value"
var rain_size = "RainDropSize:value"
var lightning_enabled = "Lightning/CheckBox:button_pressed"

# Preconfigured weather categories
var preconfigurations := {
	"Clear Sky": {
		haziness: 3,
		cloudiness: 10,
		wind_speed: 5,
		rain_enabled: false,
		lightning_enabled: false
	},
	"Few Clouds": {
		haziness: 10,
		cloudiness: 20,
		wind_speed: 15,
		rain_enabled: false,
		lightning_enabled: false
	},
	"Overcast": {
		haziness: 45,
		cloudiness: 90,
		wind_speed: 20,
		rain_enabled: false,
		lightning_enabled: false
	},
	"Drizzle Rain": {
		haziness: 25,
		cloudiness: 65,
		wind_speed: 5,
		rain_enabled: true,
		rain_density: 3.5,
		rain_size: 0.015,
		lightning_enabled: false
	},
	"Gusts": {
		haziness: 10,
		cloudiness: 35,
		wind_speed: 80,
		rain_enabled: false,
		lightning_enabled: false
	},
	"Thunderstorm": {
		haziness: 70,
		cloudiness: 85,
		wind_speed: 5,
		rain_enabled: true,
		rain_density: 7.5,
		rain_size: 0.04,
		lightning_enabled: true
	},
	"Foggy": {
		haziness: 100,
		cloudiness: 70,
		wind_speed: 0,
		rain_enabled: false,
		lightning_enabled: false
	}
}
