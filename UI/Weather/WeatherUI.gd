extends VBoxContainer


var weather_manager: WeatherManager

func _ready():
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
