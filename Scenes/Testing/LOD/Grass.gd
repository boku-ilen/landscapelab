extends Particles

export var rows = 100 setget set_rows, get_rows
export var spacing = 10.0 setget set_spacing, get_spacing

var mat = preload("res://Materials/GrassParticles.tres")

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

#func _process(delta):
#	# Center our particles on our cameras position
#	var viewport = get_viewport()
#	var camera = viewport.get_camera()
#
#	var pos = camera.global_transform.origin
#	pos.y = 0.0
#	global_transform.origin = pos