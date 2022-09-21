extends Area3D
class_name PolygonPoint


@onready var line_to_next = get_node("Node/LineToNext")

var color = Color(1, 0.227451, 0) :
	get:
		return color # TODOConverter40 Non existent get function 
	set(c):
		color = c
		$MeshInstance3D.material_override.albedo_color = c

var idx: int

var position_2D: Vector2 :
	get:
		return position_2D # TODOConverter40 Non existent get function 
	set(vec):
		position = Vector3(vec.x, vec.y, 0)
		position_2D = vec


func _process(delta):
	$SubViewport/CenterContainer/Label.text = var_to_str(idx)
