extends Spatial

onready var Blades = get_node("Blades")

export(float) var speed = 1 # Rotation speed in radians

func _physics_process(delta):
	Blades.transform.basis = Blades.transform.basis.rotated(Vector3(0, 0, 1), speed * delta)