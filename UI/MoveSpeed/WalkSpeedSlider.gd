extends HSlider

#
# Slider which modifies the walk_speed in the PlayerInfo singleton, which is accessed in the
# first person controller, thus moving faster or slower.
#

var MIN_SPEED = Settings.get_setting("player", "walk-speed-min")
var MAX_SPEED = Settings.get_setting("player", "walk-speed-max")
var DEFAULT = Settings.get_setting("player", "walk-speed-default")


func _ready():
	connect("value_changed", self, "_on_value_changed")
	
	min_value = MIN_SPEED
	max_value = MAX_SPEED

	value = DEFAULT
	

func _on_value_changed(new_val: float):
	PlayerInfo.walk_speed = new_val
