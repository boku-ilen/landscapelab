extends VSplitContainer


func _ready():
	if $Bot.get_child_count() == 0 && $Top.get_child_count() == 0:
		toggle_visibility(false)
	else:
		toggle_visibility(true)


func toggle_visibility(is_split_visible: bool):
	visible = is_split_visible
