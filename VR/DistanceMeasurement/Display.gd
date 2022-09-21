extends Control


var distance :
	get:
		return distance
	set(value):
		distance = value
		if distance is float or distance is int:
			$VBoxContainer/Distance.text = var_to_str(distance * conversion_factor)
		else:
			$VBoxContainer/Distance.text = value

var conversion_factor = 1.0 :
	get:
		return conversion_factor
	set(factor):
		conversion_factor = factor
		distance = self.distance
		if distance is float or distance is int:
			$VBoxContainer/Distance.text = var_to_str(self.distance * conversion_factor)



func _ready():
	$VBoxContainer/HBoxContainer/Metres.connect("pressed",Callable(self,"set_conversion").bind(1.0))
	$VBoxContainer/HBoxContainer/Metres.connect("pressed",Callable(self,"untoggle").bind($VBoxContainer/HBoxContainer/Yards))
	$VBoxContainer/HBoxContainer/Yards.connect("pressed",Callable(self,"set_conversion").bind(0.9144))
	$VBoxContainer/HBoxContainer/Yards.connect("pressed",Callable(self,"untoggle").bind($VBoxContainer/HBoxContainer/Metres))


func is_pressed(pressed):
	$VBoxContainer/PressedButton.button_pressed = pressed


func untoggle(node: Node):
	node.button_pressed = false
