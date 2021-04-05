extends WindowDialog


signal new_normal_scale(scale)
signal new_roughness_scale(scale, is_increase)
signal new_specular_scale(scale, is_increase)
signal new_ao_scale(scale, is_increase)


func _ready():
	$Settings/NormalScale/HSlider.connect("value_changed", self, "_on_new_normal_scale")
	$Settings/Roughness/HSlider.connect("value_changed", self, "_on_new_asymmetric_scale", ["new_roughness_scale"])
	$Settings/Specularity/HSlider.connect("value_changed", self, "_on_new_asymmetric_scale", ["new_specular_scale"])
	$Settings/AmbientOcclusion/HSlider.connect("value_changed", self, "_on_new_asymmetric_scale", ["new_ao_scale"])


func _on_new_normal_scale(value: float):
	emit_signal("new_normal_scale", value)


func _on_new_asymmetric_scale(value: float, signal_name: String):
	var is_increase = true
	if value < 0.0:
		is_increase = false
		value = -value
	
	emit_signal(signal_name, value, is_increase)
