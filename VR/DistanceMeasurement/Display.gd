extends Control


var distance :
	get:
		return distance # TODOConverter40 Copy here content of get_distance
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_distance 
var conversion_factor = 1.0 :
	get:
		return conversion_factor # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_conversion


func _ready():
	$VBoxContainer/HBoxContainer/Metres.connect("pressed",Callable(self,"set_conversion").bind(1.0))
	$VBoxContainer/HBoxContainer/Metres.connect("pressed",Callable(self,"untoggle").bind($VBoxContainer/HBoxContainer/Yards))
	$VBoxContainer/HBoxContainer/Yards.connect("pressed",Callable(self,"set_conversion").bind(0.9144))
	$VBoxContainer/HBoxContainer/Yards.connect("pressed",Callable(self,"untoggle").bind($VBoxContainer/HBoxContainer/Metres))


func set_distance(value):
	distance = value
	if distance is float or distance is int:
		$VBoxContainer/Distance.text = var_to_str(distance * conversion_factor)
	else:
		$VBoxContainer/Distance.text = value


func get_distance():
	return distance


func is_pressed(pressed):
	$VBoxContainer/PressedButton.button_pressed = pressed


func set_conversion(factor: float):
	conversion_factor = factor
	distance = get_distance()
	if distance is float or distance is int:
		$VBoxContainer/Distance.text = var_to_str(get_distance() * conversion_factor)


func untoggle(node: Node):
	node.button_pressed = false
