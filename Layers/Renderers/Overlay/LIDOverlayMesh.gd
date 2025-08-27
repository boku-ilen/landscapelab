@tool
extends MeshInstance3D


@export var lid := 0 :
	set(new_lid):
		lid = new_lid
		update_mesh_color()

@export var size := Vector2(5.0, 5.0) :
	set(new_size):
		size = new_size
		update_size()


# Called when the node enters the scene tree for the first time.
func _ready():
	update_size()
	update_mesh_color()


func update_mesh_color():
	material_override.set_shader_parameter("color", Color8(
		lid % 255,
		floor(lid / 255),
		0
	))


func update_size():
	if "size" in mesh:
		mesh.size = size
