extends Window


var weather_manager:
	set(new_weather_manager):
		weather_manager = new_weather_manager
		$PanelContainer/WeatherUI.weather_manager = weather_manager


func _ready():
	close_requested.connect(hide)
