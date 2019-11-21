extends Spatial

#
# Attach this scene to MousePoint.tscn. 
# Once the setting_path bool is enabled, with the mapped inputs of "imaging_set_path" and
# "imaging_set_focus" a path and a focussed point can be set.
#

export var height_above_ground: float
export var path_mesh_size: float

onready var focus: Spatial = get_node("Focus")
onready var path: Path = get_node("Path")
onready var path_mesh: LinearCSGPolygon = get_node("Path/PathFollow/PathTexture")
onready var cursor: RayCast = get_parent().get_node("InteractRay")

var currently_imaging: bool = false
var height_correction: Vector3


func _ready():
	path_mesh.set_width(path_mesh_size)
	path_mesh.set_height(path_mesh_size)
	height_correction = Vector3(0, height_above_ground, 0)


func _input(event):
	if event.is_action_pressed("imaging"):
		_switch_imaging_mode()
	elif currently_imaging:
		
		if event.is_action_pressed("imaging_set_path"):
			var position = WorldPosition.get_position_on_ground(cursor.get_collision_point())
			_add_path_point(position)
		elif event.is_action_pressed("imaging_set_focus"):
			var position = WorldPosition.get_position_on_ground(cursor.get_collision_point())
			_set_focus_position(position)


func _switch_imaging_mode():
	currently_imaging = !currently_imaging


func _add_path_point(position):
	path.curve.add_point(position + height_correction)


func _set_focus_position(position):
	focus.global_transform.origin = (position + height_correction)
