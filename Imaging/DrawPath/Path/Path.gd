extends Spatial


# As we do not want to have the line directly on the ground there will be a placeholder value
export var height_above_ground: float
export var path_mesh_size: float

onready var focus: Spatial = get_node("Focus")
onready var path: Path = get_node("Path")
onready var path_mesh: LinearCSGPolygon = get_node("Path/PathFollow/PathMesh")

var height_correction: Vector3


func _ready():
	path_mesh.set_width(path_mesh_size)
	path_mesh.set_height(path_mesh_size)
	height_correction = Vector3(0, height_above_ground, 0)
	
	GlobalSignal.connect("imaging_add_path_point", self, "_add_path_point")
	GlobalSignal.connect("imaging_set_focus", self, "_set_focus_position")


func _add_path_point(position):
	path.curve.add_point(position + height_correction)


func _set_focus_position(position):
	focus.global_transform.origin = (position + height_correction)

