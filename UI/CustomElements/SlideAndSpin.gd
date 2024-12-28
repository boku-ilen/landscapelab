@tool
extends HBoxContainer
class_name SlideAndSpin

signal value_changed(value)

@export var label := "" :
	get:
		return label
	set(text):
		label = text
		if has_node("Label"):
			$Label.text = text

@export var min_value := 0.0 :
	get:
		return min_value
	set(val):
		min_value = val
		if has_node("SpinBox") and has_node("HSlider"):
			$SpinBox.min_value = val
			$HSlider.min_value = val

@export var max_value := 100.0 :
	get:
		return max_value
	set(val):
		max_value = val
		if has_node("SpinBox") and has_node("HSlider"):
			$SpinBox.max_value = val
			$HSlider.max_value = val

@export var step := 1.0 :
	get:
		return step
	set(val):
		step = val
		if has_node("SpinBox") and has_node("HSlider"):
			$SpinBox.step = val
			$HSlider.step = val

@export var value := 50.0 :
	get:
		return value 
	set(val):
		value = val
		if has_node("SpinBox"):
			$SpinBox.value = val
			
		if has_node("HSlider"):
			$HSlider.value = val
		
		if has_node("ValueLabel"):
			$ValueLabel.text = "%1d" % val


@export var tick_count := 0 : 
	set(new_tick_counter):
		tick_count = new_tick_counter
		if has_node("HSlider"):
			$HSlider.tick_count = tick_count


@export var is_text_editable := false : 
	set(new_is_text_editable):
		is_text_editable = new_is_text_editable
		$SpinBox.visible = is_text_editable
		$ValueLabel.visible = not is_text_editable


func _ready():
	$HSlider.connect("value_changed",Callable(self,"_update_value"))
	$SpinBox.connect("value_changed",Callable(self,"_update_value"))
	value = clamp(value, min_value, max_value)
	step = step
	max_value = max_value
	min_value = min_value
	label = label
	is_text_editable = is_text_editable


func _update_value(new_value):
	value_changed.emit(new_value)
	self.value = new_value
