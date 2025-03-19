@tool
extends HBoxContainer


@export var value: float:
	set(new_value):
		value = new_value
		
		if value > 0:
			$Below.value = 0
			$Above.value = value
		else:
			$Below.value = -value
			$Above.value = 0
	get():
		return value

@export var max_value := 50.0:
	set(new_max_value):
		max_value = new_max_value
		$Below.max_value = max_value
		$Above.max_value = max_value
	get():
		return max_value
