extends Particles


export var rows = 4 setget set_rows, get_rows
export var spacing = 1.0 setget set_spacing, get_spacing

var time_passed = 0

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
	update_textures(position)
	
func _process(delta):
	global_transform.origin = PlayerInfo.get_engine_player_position()
	
	time_passed += delta
	
	if time_passed > 5.0:
		time_passed = 0.0
		
		var position = Offset.to_world_coordinates(global_transform.origin)
		update_textures(position)

func update_textures(position):
	var dhm = Geodot.get_image(
		GeodataPaths.get_absolute("heightmap"),
		GeodataPaths.get_type("heightmap"),
		-position[0] - rows / 2,
		position[2] + rows / 2,
		rows,
		256,
		1
	)
	
	var splat = Geodot.get_image(
		GeodataPaths.get_absolute("land-use"),
		GeodataPaths.get_type("land-use"),
		-position[0] - rows / 2,
		position[2] + rows / 2,
		rows,
		128,
		6
	)
	
	# Get the most common splatmap values here
	var ids = splat.get_most_common(8)
	
	var phytocoenosis = Vegetation.get_phytocoenosis_array_for_ids(ids)
	
	var filtered_phytocoenosis = Vegetation.filter_phytocoenosis_array_by_height(phytocoenosis, 0.0, 2.0)

	var time_before = OS.get_ticks_msec()
	
	var billboards = Vegetation.get_billboard_sheet(filtered_phytocoenosis)
	
	print("Billboard sheet took %d" % [OS.get_ticks_msec() - time_before])
	
	var distribution_sheet = Vegetation.get_distribution_sheet(filtered_phytocoenosis)
	
	# The rows correspond to the passed IDs.
	# The columns correspond to IDs in the distribution map.
	# TODO: Load a sheet of distribution maps
	
	# TODO: Don't equate rows with size - this way, only spacing 1 is possible
	
	process_material.set_shader_param("heightmap_size", Vector2(rows, rows))
	process_material.set_shader_param("heightmap", dhm.get_image_texture())
	material_override.set_shader_param("splatmap", splat.get_image_texture())
	
	process_material.set_shader_param("offset", Vector2(-global_transform.origin.x, -global_transform.origin.z))
	material_override.set_shader_param("offset", Vector2(-global_transform.origin.x, -global_transform.origin.z))
	
	# Create map from ID to row
	var id_row_map = Image.new()
	id_row_map.create(256, 1, false, Image.FORMAT_R8)
	id_row_map.lock()
	
	# id_row_map.fill doesn't work here - if that is used, the set_pixel calls
	#  later have no effect...
	for i in range(0, 255):
		id_row_map.set_pixel(i, 0, Color(1.0, 0.0, 0.0))
	
	var row = 0
	for id in ids:
		print(id, " ", row)
		id_row_map.set_pixel(id, 0, Color(row / 255.0, 0.0, 0.0))
		row += 1
	
	id_row_map.unlock()
	
	var id_row_map_tex = ImageTexture.new()
	id_row_map_tex.create_from_image(id_row_map, 0)
	material_override.set_shader_param("id_to_row", id_row_map_tex)
	
	var tex = ImageTexture.new()
	tex.create_from_image(billboards)
	material_override.set_shader_param("texture_map", tex)
	
	var dist = ImageTexture.new()
	dist.create_from_image(distribution_sheet, ImageTexture.FLAG_REPEAT)
	material_override.set_shader_param("distribution_map", dist)
