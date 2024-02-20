extends Node3D


@export var lid := 0 :
	set(new_lid):
		lid = new_lid
		update_mesh_color()


# Called when the node enters the scene tree for the first time.
func _ready():
	update_mesh_color()


func update_mesh_color():
	$MeshInstance3D.material_override.albedo_color = Color8(
		lid % 255,
		floor(lid / 255),
		0
	)
