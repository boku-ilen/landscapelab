extends WindowDialog


signal new_fov(value)
signal new_view_distance(value)


func _ready():
	$Settings/FOV/HSlider.connect("value_changed", self, "_on_fov_slider_changed")
	$Settings/ViewDistance/HSlider.connect("value_changed", self, "_on_view_slider_changed")


func _on_fov_slider_changed(value: float):
	emit_signal("new_fov", value)


func _on_view_slider_changed(value: float):
	emit_signal("new_view_distance", value)
