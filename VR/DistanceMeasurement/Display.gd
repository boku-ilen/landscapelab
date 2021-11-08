extends Control


var distance setget set_distance, get_distance 
var conversion_factor = 1.0 setget set_conversion


func _ready():
	$VBoxContainer/HBoxContainer/Metres.connect("pressed", self, "set_conversion", [1.0])
	$VBoxContainer/HBoxContainer/Metres.connect("pressed", self, "untoggle", [$VBoxContainer/HBoxContainer/Yards])
	$VBoxContainer/HBoxContainer/Yards.connect("pressed", self, "set_conversion", [0.9144])
	$VBoxContainer/HBoxContainer/Yards.connect("pressed", self, "untoggle", [$VBoxContainer/HBoxContainer/Metres])


func set_distance(value):
	distance = value
	if distance is float or distance is int:
		$VBoxContainer/Distance.text = String(distance * conversion_factor)
	else:
		$VBoxContainer/Distance.text = value


func get_distance():
	return distance


func is_pressed(pressed):
	$VBoxContainer/PressedButton.pressed = pressed


func set_conversion(factor: float):
	conversion_factor = factor
	distance = get_distance()
	if distance is float or distance is int:
		$VBoxContainer/Distance.text = String(get_distance() * conversion_factor)


func untoggle(node: Node):
	node.pressed = false
