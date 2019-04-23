extends HSlider


func _ready():
	connect("value_changed", self, "_on_value_changed")


func _on_value_changed(value):
	# Pass the signal forward using the global signal manager
	GlobalSignal.emit_signal("season_changed", value)
