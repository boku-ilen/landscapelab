extends "res://UI/LabTable/TableButton.gd"


var time_manager: TimeManager:
	set(new_time_manager):
		time_manager = new_time_manager
		$AtmosphereConfiguration.time_manager = new_time_manager

var weather_manager: WeatherManager:
	set(new_weather_manager):
		weather_manager = new_weather_manager
		$AtmosphereConfiguration.weather_manager = new_weather_manager


func _ready():
	$AtmospherePanel/Content/HBoxContainer/Settings/TimeSelect.item_selected.connect(_on_time_item_selected)
	$AtmospherePanel/Content/HBoxContainer/Settings/WeatherSelect.item_selected.connect(_on_weather_item_selected)
	$AtmospherePanel/Content/HBoxContainer/CurrentSettingsButton.pressed.connect(_on_current_settings_pressed)


func _toggled(toggled_on: bool) -> void:
	$AtmospherePanel.visible = not $AtmospherePanel.visible


func _on_time_item_selected(index):
	if index == 0:
		$AtmosphereConfiguration.activate_time("Sunrise")
	elif index == 1:
		$AtmosphereConfiguration.activate_time("Noon")
	elif index == 2:
		$AtmosphereConfiguration.activate_time("Sunset")
	elif index == 3:
		$AtmosphereConfiguration.activate_time("Night")


func _on_weather_item_selected(index):
	if index == 0:
		$AtmosphereConfiguration.activate_weather("Clear")
	elif index == 1:
		$AtmosphereConfiguration.activate_weather("Few Clouds")
	elif index == 2:
		$AtmosphereConfiguration.activate_weather("Drizzle Rain")
	elif index == 3:
		$AtmosphereConfiguration.activate_weather("Thunderstorm")


func _on_current_settings_pressed():
	$AtmosphereConfiguration.apply_current_values()
