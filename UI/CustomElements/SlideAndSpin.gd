extends HBoxContainer
class_name SlideAndSpin
tool

export var label := "" setget set_label
export var min_value := 0.0 setget set_min_value
export var max_value := 100.0 setget set_max_value
export var step := 1.0 setget set_step
export var value := 50.0 setget set_value

func set_label(text: String):
	label = text
	$Label.text = text

func set_value(val: float):
	value = val
	$SpinBox.value = val
	$HSlider.value = val

func set_step(val: float):
	step = val
	$SpinBox.step = val
	$HSlider.step = val

func set_min_value(val: float):
	min_value = val
	$SpinBox.min_value = val
	$HSlider.min_value = val

func set_max_value(val: float):
	max_value = val
	$SpinBox.max_value = val
	$HSlider.max_value = val


func _ready():
	$HSlider.connect("value_changed", self, "_update_spinbox")
	$SpinBox.connect("value_changed", self, "_update_slider")


func _update_spinbox(value):
	$SpinBox.value = value


func _update_slider(value):
	$HSlider.value = value
