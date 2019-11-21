extends ViewportContainer


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_imaging_view"):
		visible = !visible
