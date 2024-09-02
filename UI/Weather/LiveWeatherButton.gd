extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect($LiveWeatherService.apply_current_weather)
