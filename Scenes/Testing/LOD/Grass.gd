extends Particles

#
# This script sets up the grass particle shader. 
#

export var rows = 100 setget set_rows, get_rows
export var spacing = 10.0 setget set_spacing, get_spacing

var mat = preload("res://Materials/GrassParticles.tres")

export(Material) var grass_mat = preload("res://Materials/GrassMaterial.tres")

# Set alternative material
func set_mat(_mat):
	process_material = _mat.duplicate()
	
func set_noise_offset(offset):
	if process_material:
		process_material.set_shader_param("random_offset", offset)

func update_aabb():
	var size = rows * spacing
	visibility_aabb = AABB(Vector3(-0.5 * size, 0.0, -0.5 * size), Vector3(size, 20.0, size))

func set_rows(new_rows):
	rows = new_rows
	amount = rows * rows
	update_aabb()
	if process_material:
		process_material.set_shader_param("rows", rows)

func get_rows():
	return rows

func set_spacing(new_spacing):
	spacing = new_spacing
	update_aabb()
	if process_material:
		process_material.set_shader_param("spacing", spacing)

func get_spacing():
	return spacing

func _ready():
	# now that our material has been constructed, re-issue these
	set_rows(rows)
	process_material = mat.duplicate()
	material_override = grass_mat.duplicate()
	set_noise_offset(randf())