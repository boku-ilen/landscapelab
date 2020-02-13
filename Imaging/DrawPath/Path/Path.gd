extends "res://Util/LinearDrawer/InterpolateLinear.gd"


# As we do not want to have the line directly on the ground there will be a placeholder value
export var height_above_ground: float

onready var focus: Spatial = get_node("Focus")
onready var path: Path = get_node("Path")

onready var height_correction = Vector3(0, height_above_ground, 0)


func _ready():
	GlobalSignal.connect("imaging_add_path_point", self, "_add_path_point")
	GlobalSignal.connect("imaging_set_focus", self, "_set_focus_position")
	UISignal.connect("clear_imaging_path", self, "_on_clear")
	Offset.connect("shift_world", self, "on_shift_world")


func on_shift_world(delta_x, delta_z):
	global_transform.origin += Vector3(delta_x, 0, delta_z)


func _add_path_point(position):
	var all_points = path.curve.get_baked_points()
	
	if not all_points.empty():
		var last_point = path.curve.get_point_position(path.curve.get_point_count() - 1)
		
		var possible_interpolated: Array = interpolate_points(last_point, position + height_correction)
		for point in possible_interpolated:
			point = WorldPosition.get_position_on_ground(point) + height_correction
			
			path.curve.add_point(point)
	else:
		path.curve.add_point(position + height_correction)


func _set_focus_position(position):
	focus.global_transform.origin = (position + height_correction)


func _on_clear():
	path.get_curve().clear_points()
