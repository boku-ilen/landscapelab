extends GridContainer


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print(event)
