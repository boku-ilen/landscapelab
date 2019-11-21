extends Spatial

onready var foucs: Spatial = get_node("Focus")
onready var path: Path = get_node("Path")
onready var cursor: RayCast = get_parent().get_node("RayCast")
var setting_path: bool = false



func _input(event):
	if event.is_action_pressed("imaging"):
		_switch_path_mode()
	elif setting_path:
		if event.is_action_pressed("imaging_set_path"):
			print("setting path")
		elif event.is_action_pressed("imaging_set_focus"):
			print("setting focus")


func _switch_path_mode():
	setting_path = !setting_path


