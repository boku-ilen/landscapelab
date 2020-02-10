extends Path


func _ready():
	Offset.connect("shift_world", self, "on_shift_world")


func on_shift_world(delta_x, delta_z):
	global_transform.origin += Vector3(delta_x, 0, delta_z)
