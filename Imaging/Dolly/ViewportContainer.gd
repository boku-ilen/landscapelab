extends ViewportContainer


onready var camera = get_node("RecordingViewport/DollyCamera")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_imaging_view"):
		visible = !visible
		
		if visible:
			# FIXME: Ugly... but 0 doesn't move it to the beginning of the path
			camera.path_follow.offset = 0.0001
