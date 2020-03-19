extends InteractableObject

export(float) var pew_jectile_speed = 100

onready var pew_jectile = preload("res://testing/InteractableObjects/PewPew/PewJectile.tscn")
onready var meshes = get_node("Spatial")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func interact():
	var projectile = pew_jectile.instance()
	var mesh = projectile.get_node("MeshInstance").mesh
	var forward = -(meshes.global_transform.basis.z)
	get_tree().get_root().add_child(projectile)
	projectile.global_transform = meshes.global_transform
	projectile.global_transform.origin = meshes.global_transform.origin + forward * mesh.mid_height
	projectile.apply_impulse(meshes.global_transform.origin, forward * pew_jectile_speed)
