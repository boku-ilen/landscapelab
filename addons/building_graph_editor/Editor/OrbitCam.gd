@tool
extends Camera3D
class_name OrbitCam

var angle := 0.0
@export var orbit_speed = 0.1
@export var dist = 26.0
@export var height = 5.0
@export var offset = 0.0

func _ready() -> void:
	#dist = position.z
	angle = offset

func _process(delta: float) -> void:
	#angle = wrapf(angle + orbit_speed * delta, 0, 2 * PI)
	var pos_2d = Vector2.from_angle(offset) * dist
	position = Vector3(pos_2d.x, height, pos_2d.y)
	look_at(Vector3(0,0,0))
	