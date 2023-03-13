@tool
extends HBoxContainer
class_name SlideAndSpin

@export var label := "" :
	get:
		return label
	set(text):
		label = text
		if $Label:
			$Label.text = text

@export var min_value := 0.0 :
	get:
		return min_value
	set(val):
		min_value = val
		if $SpinBox and $HSlider:
			$SpinBox.min_value = val
			$HSlider.min_value = val

@export var max_value := 100.0 :
	get:
		return max_value
	set(val):
		max_value = val
		if $SpinBox and $HSlider:
			$SpinBox.max_value = val
			$HSlider.max_value = val

@export var step := 1.0 :
	get:
		return step
	set(val):
		step = val
		if $SpinBox and $HSlider:
			$SpinBox.step = val
			$HSlider.step = val

@export var value := 50.0 :
	get:
		return value 
	set(val):
		value = val
		if $SpinBox and $HSlider:
			$SpinBox.value = val
			$HSlider.value = val


func _ready():
	$HSlider.connect("value_changed",Callable(self,"_update_value"))
	$SpinBox.connect("value_changed",Callable(self,"_update_value"))
	value = value
	step = step
	max_value = max_value
	min_value = min_value
	label = label


func _update_value(new_value):
	self.value = new_value
