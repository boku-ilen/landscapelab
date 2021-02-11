extends VSplitContainer


func _ready():
	if $Bot.get_child_count() == 0 && $Top.get_child_count() == 0:
		toggle_visibility(false)
	else:
		toggle_visibility(true)


func toggle_visibility(is_visible: bool):
	if is_visible:
		visible = true
	else:
		visible = false
