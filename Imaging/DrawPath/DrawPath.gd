extends Spatial

#
# Attach this scene to MousePoint.tscn. 
# Once the setting_path bool is enabled, with the mapped inputs of "imaging_set_path" and
# "imaging_set_focus" a path and a focussed point can be set.
#

export var path_texture: CurveTexture

onready var focus: Spatial = get_node("Focus")
onready var path: Path = get_node("Path")
onready var cursor: RayCast = get_parent().get_node("InteractRay")

var setting_path: bool = false


func _ready():
	path_texture.set_width(5)
	#path_texture.set_curve(path.curve)

func _input(event):
	if event.is_action_pressed("imaging"):
		_switch_path_mode()
	elif setting_path:
		if event.is_action_pressed("imaging_set_path"):
			_add_path_point(WorldPosition.get_position_on_ground(cursor.get_collision_point()))
		elif event.is_action_pressed("imaging_set_focus"):
			_set_focus_position(WorldPosition.get_position_on_ground(cursor.get_collision_point()))


func _switch_path_mode():
	setting_path = !setting_path


func _add_path_point(position):
	path.curve.add_point(position)


func _set_focus_position(position):
	focus.global_transform.origin = position
