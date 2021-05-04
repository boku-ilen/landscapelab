extends Area
class_name PolygonPoint


onready var line_to_next = get_node("Node/LineToNext")

var color = Color(1, 0.227451, 0) setget set_color 

var idx: int
var position: Vector2 setget set_position


func set_position(vec: Vector2):
	translation = Vector3(vec.x, vec.y, 0)
	position = vec


func set_color(c: Color):
	color = c
	$MeshInstance.material_override.albedo_color = c


func _process(delta):
	$Viewport/CenterContainer/Label.text = String(idx)
