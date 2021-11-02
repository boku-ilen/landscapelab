extends VBoxContainer


var weather_manager: WeatherManager


func _ready():
	$Visibility/HSlider.connect("value_changed", self, "_on_visibility_changed")
	$Clouds/HSlider.connect("value_changed", self, "_on_cloudiness_changed")
	$Unshaded/CheckBox.connect("toggled", self, "_on_unshaded_changed")


func _on_visibility_changed(value):
	weather_manager.set_visibility(value)


func _on_cloudiness_changed(value):
	weather_manager.set_cloudiness(value)


func _on_unshaded_changed(value):
	weather_manager.set_is_unshaded(value)
