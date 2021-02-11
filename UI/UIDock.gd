extends Control


func _ready():
	if get_child_count() == 0:
		toggle_visibility(false)
	else:
		toggle_visibility(true)


func toggle_visibility(is_visible: bool):
	if is_visible:
		visible = true
	else:
		visible = false
