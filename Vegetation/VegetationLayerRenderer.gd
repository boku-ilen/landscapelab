extends Particles


export var rows = 4 setget set_rows, get_rows
export var spacing = 1.0 setget set_spacing, get_spacing

func update_aabb():
	var size = rows * spacing
	visibility_aabb = AABB(Vector3(-0.5 * size, -1000.0, -0.5 * size), Vector3(size, 10000.0, size))

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_rows(rows)
	
	var position = Offset.to_world_coordinates(global_transform.origin)
	
	var dhm = Geodot.get_image(
		GeodataPaths.get_absolute("heightmap"),
		GeodataPaths.get_type("heightmap"),
		-position[0] - rows / 2,
		position[2] + rows / 2,
		rows,
		100,
		1
	)
	
	var splat = Geodot.get_image(
		GeodataPaths.get_absolute("splatmap"),
		GeodataPaths.get_type("splatmap"),
		-position[0] - rows / 2,
		position[2] + rows / 2,
		rows,
		100,
		1
	)
	
	# TODO: Don't equate rows with size - this way, only spacing 1 is possible
	
	process_material.set_shader_param("heightmap_size", Vector2(rows, rows))
	process_material.set_shader_param("heightmap", dhm.get_image_texture())
	material_override.set_shader_param("splatmap", splat.get_image_texture())
