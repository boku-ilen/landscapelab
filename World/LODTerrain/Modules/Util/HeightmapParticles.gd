tool
extends Particles

#
# This script sets up the HeightmapParticles shader which renders rows and columns of particles,
# the height of which depends on a heightmap.
# It is used for the vegetation.
#

export var rows = 100 setget set_rows, get_rows
export var spacing = 10.0 setget set_spacing, get_spacing


# Set alternative material
func set_mat(_mat):
	process_material = _mat.duplicate()


# A random number should be used here to pass as an offset to the shader. This prevents multiple particle
#  systems on the same location from having the same offsets and rotations.
func set_noise_offset(offset):
	if process_material:
		process_material.set_shader_param("random_offset", offset)


# Update the visilibity bounding box depending on the size
func update_aabb():
	var size = rows * spacing
	visibility_aabb = AABB(Vector3(-0.5 * size, 500.0, -0.5 * size), Vector3(0.5 * size, 3000.0, 0.5 * size))


# Specify how many rows and columns of particles there should be
func set_rows(new_rows):
	rows = new_rows
	amount = rows * rows
	update_aabb()
	if process_material:
		process_material.set_shader_param("rows", rows)


func get_rows():
	return rows


# Specify the space that should be between two particles (only approximate, since they will be
#  slightly randomly offset)
func set_spacing(new_spacing):
	spacing = new_spacing
	update_aabb()
	if process_material:
		process_material.set_shader_param("spacing", spacing)


func get_spacing():
	return spacing


# Specify the mesh that should be used for the particles
func set_mesh(mesh):
	draw_pass_1 = mesh
	

# Emit the particles. Since this particle system is one-shot, this needs to be done
#  after all parameters have been set.
func emit():
	emitting = true


func _ready():
	set_noise_offset(randf())
