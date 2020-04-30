extends Particles


# With 4 rows and a spacing of 0.5, plants are drawn within a 2x2 area.
export var rows = 4 setget set_rows, get_rows
export var spacing = 1.0 setget set_spacing, get_spacing

# Min and max size of plants which this layer should render.
# Should usually correspond to the mesh which is used to draw the plants.
export(float) var min_size
export(float) var max_size

# To allow some movement without having to load new data, not only the area
#  given by rows * spacing is loaded, but this additional map size is added.
# Thus, there's no need to load new data immediately, and it's not a problem if
#  it takes a while to load.
export(float) var additional_map_size = 1000

var time_passed = 0

var load_thread = Thread.new()

var previous_origin

var current_offset_from_shifting = Vector2.ZERO

# Updates the visibility aabb which is used for culling.
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
	Offset.connect("shift_world", self, "_on_shift_world")
	
	set_rows(rows)
	set_spacing(spacing)
	
	previous_origin = global_transform.origin
	var position = Offset.to_world_coordinates(global_transform.origin)
	update_textures(position)


# When the world is shifted, this offset needs to be remembered and passed to
#  the shader so that the world -> UV calculation remains correct.
func _on_shift_world(delta_x, delta_z):
	current_offset_from_shifting -= Vector2(delta_x, delta_z)
	
	process_material.set_shader_param("offset", Vector2(-previous_origin.x, -previous_origin.z) + current_offset_from_shifting)
	material_override.set_shader_param("offset", Vector2(-previous_origin.x, -previous_origin.z) + current_offset_from_shifting)


func _process(delta):
	global_transform.origin = PlayerInfo.get_engine_player_position()
	
	time_passed += delta
	
	# If no data is currently loading and we've moved 1/2 of the distance we can
	#  move within the available data, start getting some new data.
	if not load_thread.is_active() \
			and (previous_origin - global_transform.origin).length() \
			> additional_map_size / 4.0:
		previous_origin = global_transform.origin
		
		var position = Offset.to_world_coordinates(global_transform.origin)
		
		load_thread.start(self, "update_textures", position)


func _input(event):
	if event.is_action("toggle_vegetation") and event.pressed:
		visible = not visible


func update_textures(position):
	var map_size =  rows * spacing * 2
	
	var dhm = Geodot.get_image(
		GeodataPaths.get_absolute("heightmap"),
		GeodataPaths.get_type("heightmap"),
		-position[0] - map_size / 2,
		position[2] + map_size / 2,
		map_size,
		map_size / 2.0,
		1
	)
	
	var splat = Geodot.get_image(
		GeodataPaths.get_absolute("land-use"),
		GeodataPaths.get_type("land-use"),
		-position[0] - map_size / 2,
		position[2] + map_size / 2,
		map_size,
		map_size / 10.0,
		0
	)
	
	# Get the most common splatmap values here
	var ids = splat.get_most_common(8)
	
	# Loat the phytocoenosis for these IDs and filter them by the given size
	#  parameters
	var phytocoenosis = Vegetation.get_phytocoenosis_array_for_ids(ids)
	var filtered_phytocoenosis = Vegetation.filter_phytocoenosis_array_by_height(phytocoenosis, min_size, max_size)
	
	var billboards = Vegetation.get_billboard_sheet(filtered_phytocoenosis)
	
	# If billboards is null, this means that there were 0 plants in all of the
	#  phytocoenosis. Then, we don't need to render anything.
	if not billboards:
		amount = 0
		return
	
	var distribution_sheet = Vegetation.get_distribution_sheet(filtered_phytocoenosis)
	
	# All spritesheets are organized like this:
	# The rows correspond to land-use values
	# The columns correspond to distribution values
	
	# To map land-use values to a row from 0-7, we create another texture.
	# An array would be more straightforward, but shaders don't accept these as
	#  uniform parameters.
	var id_row_map = Image.new()
	id_row_map.create(256, 1, false, Image.FORMAT_R8)
	id_row_map.lock()
	
	# id_row_map.fill doesn't work here - if that is used, the set_pixel calls
	#  later have no effect...
	for i in range(0, 255):
		id_row_map.set_pixel(i, 0, Color(1.0, 0.0, 0.0))
	
	# The pixel at x=id (0-255) is set to the row value (0-7).
	var row = 0
	for id in ids:
		id_row_map.set_pixel(id, 0, Color(row / 255.0, 0.0, 0.0))
		row += 1
	
	id_row_map.unlock()
	
	# Fill all parameters into the shader
	var id_row_map_tex = ImageTexture.new()
	id_row_map_tex.create_from_image(id_row_map, 0)
	material_override.set_shader_param("id_to_row", id_row_map_tex)
	
	var tex = ImageTexture.new()
	tex.create_from_image(billboards)
	material_override.set_shader_param("texture_map", tex)
	
	var dist = ImageTexture.new()
	dist.create_from_image(distribution_sheet, ImageTexture.FLAG_REPEAT)
	material_override.set_shader_param("distribution_map", dist)
	
	process_material.set_shader_param("heightmap_size", Vector2(map_size, map_size))
	material_override.set_shader_param("heightmap_size", Vector2(map_size, map_size))
	
	process_material.set_shader_param("heightmap", dhm.get_image_texture())
	material_override.set_shader_param("splatmap", splat.get_image_texture())
	
	process_material.set_shader_param("offset", Vector2(-previous_origin.x, -previous_origin.z))
	material_override.set_shader_param("offset", Vector2(-previous_origin.x, -previous_origin.z))
	
	current_offset_from_shifting = Vector2.ZERO
	
	# Finish the shader so that it can accept new loading requests again
	call_deferred("_update_done")


func _update_done():
	load_thread.wait_to_finish()
