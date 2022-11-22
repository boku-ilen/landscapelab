extends GPUParticles3D


# With 4 rows and a spacing of 0.5, plants are drawn within a 2x2 area.
@export var rows = 4
@export var spacing = 1.0

# Density class of this plant renderer -- influences the density of the rendered particles.
var density_class: DensityClass :
	get:
		return density_class
	set(new_density_class):
		density_class = new_density_class
		
		update_rows_spacing(Vegetation.plant_extent_factor)

@export var offset: Vector2 = Vector2.ZERO

@export var camera_facing_enabled := false :
	get:
		return camera_facing_enabled
	set(is_enabled):
		camera_facing_enabled = is_enabled
		# A density class is required for sensible setting of billboard mode
		if not density_class: return
		if is_enabled:
			# Render solitary plants as camera-facing billboards, clusters as static meshes
			if density_class.image_type == "Solitary":
				set_mesh(load("res://Resources/Meshes/VegetationBillboard/1m_billboard_camerafacing.obj"))
				set_camera_facing(true)
			else:
				set_mesh(load("res://Resources/Meshes/VegetationBillboard/1m_billboard.obj"))
				set_camera_facing(false)
		else:
			set_mesh(load("res://Resources/Meshes/VegetationBillboard/1m_billboard.obj"))
			set_camera_facing(false)

var current_offset_from_shifting = Vector2.ZERO
var time_passed = 0
var previous_origin

# Data
var id_row_array
var billboard_tex
var distribution_tex
var heightmap
var splatmap


func _ready():
	self.camera_facing_enabled = camera_facing_enabled
	Vegetation.connect("new_plant_extent_factor",Callable(self,"update_rows_spacing"))


# Set the internal rows and spacing variables based checked the density_class and the given extent_factor.
func update_rows_spacing(extent_factor):
	var size = extent_factor * density_class.size_factor
	
	rows = floor(size * density_class.density_per_m)
	spacing = 1.0 / density_class.density_per_m
	
	set_rows(rows)
	set_spacing(spacing)
	
	update_aabb()


func set_mesh(new_mesh):
	draw_pass_1 = new_mesh


func set_camera_facing(is_camera_facing: bool) -> void:
	material_override.set_shader_parameter("camera_facing", is_camera_facing)
	material_override.set_shader_parameter("billboard_enabled", is_camera_facing)


# Updates the visibility AABB which is used for culling.
func update_aabb():
	var size = rows * spacing
	visibility_aabb = AABB(Vector3(-0.5 * size, -1000.0, -0.5 * size), Vector3(size, 10000.0, size))


func set_rows(new_rows):
	rows = new_rows
	amount = rows * rows
	
	if process_material:
		process_material.set_shader_parameter("rows", rows)
		material_override.set_shader_parameter("max_distance", rows * spacing / 3.0)


func set_spacing(new_spacing):
	spacing = new_spacing
	
	if process_material:
		process_material.set_shader_parameter("spacing", spacing)
		material_override.set_shader_parameter("max_distance", rows * spacing / 3.0)


# Return the size of the loaded GeoImage, which is at least as large as rows * spacing.
func get_map_size():
	return rows * spacing * 1.5 + 100 # Add 100 to allow for some movement within the data


# When the world is shifted, this offset needs to be remembered and passed to
#  the shader so that the world -> UV calculation remains correct.
func _on_shift_world(delta_x, delta_z):
	current_offset_from_shifting -= Vector2(delta_x, delta_z)
	
	process_material.set_shader_parameter("offset", Vector2(-previous_origin.x, -previous_origin.z) + current_offset_from_shifting)
	material_override.set_shader_parameter("offset", Vector2(-previous_origin.x, -previous_origin.z) + current_offset_from_shifting)


# Update all internal data based checked the given layers and position.
func update_textures(dhm_layer, splat_layer, world_x, world_y):
	var map_size = get_map_size()
	
	var dhm = dhm_layer.get_image(
		float(world_x - map_size / 2),
		float(world_y + map_size / 2),
		float(map_size), 
		int(map_size / 2.0),
		1
	)
	
	heightmap = dhm.get_image_texture()
	
	var splat = splat_layer.get_image(
		float(world_x - map_size / 2),
		float(world_y + map_size / 2),
		float(map_size), 
		int(map_size / 2.0),
		0
	)
	
	splatmap = splat.get_image_texture()
	
	update_textures_with_images(splat.get_most_common(32))


# Directly update the vegetation data with given ImageTextures. Can be used e.g. for testing with
#  artificially created data. Is also called internally when `update_textures` is used.
# Should be called in a thread to avoid stalling the main thread.
func update_textures_with_images(ids):
	var map_size = get_map_size()
	
	# Load the groups for these IDs and filter them by the given density class
	var groups = Vegetation.get_group_array_for_ids(ids)
	var filtered_groups = Vegetation.filter_group_array_by_density_class(groups, density_class)
	
	billboard_tex = Vegetation.get_billboard_texture(filtered_groups)
	
	# If billboards is null, this means that there were 0 plants in all of the
	#  groups. Then, we don't need to render anything.
	if not billboard_tex:
		visible = false
		return
	else:
		visible = true
	
	var distribution_sheet = Vegetation.get_distribution_sheet(filtered_groups)
	
	# All spritesheets are organized like this:
	# The rows correspond to land-use values
	# The columns correspond to distribution values
	
	id_row_array = Vegetation.get_id_row_array(Vegetation.get_id_array_for_groups(filtered_groups))
	
	distribution_tex = ImageTexture.create_from_image(distribution_sheet) #,ImageTexture.FLAG_REPEAT


# Apply data which has previously been loaded with `update_textures`.
# Should not be called from a thread.
func apply_data():
	process_material.set_shader_parameter("id_to_row", id_row_array)
	process_material.set_shader_parameter("distribution_map", distribution_tex)
	process_material.set_shader_parameter("splatmap", splatmap)
	process_material.set_shader_parameter("splatmap_size_meters", get_map_size())
	process_material.set_shader_parameter("dist_scale", 1.0 / spacing)
	
	material_override.set_shader_parameter("texture_map", billboard_tex)
	
	var size = Vector2(get_map_size(), get_map_size())
	process_material.set_shader_parameter("heightmap_size", size)
	material_override.set_shader_parameter("heightmap_size", size)
	
	process_material.set_shader_parameter("heightmap", heightmap)
	
	process_material.set_shader_parameter("offset", Vector2(0, 0))
	material_override.set_shader_parameter("offset", Vector2(0, 0))
	
	# Row crops
	if density_class.id == 6:
		process_material.set_shader_parameter("row_spacing", 3.0)
	

func apply_wind_speed(wind_speed):
	material_override.set_shader_parameter("speed", Vector2(wind_speed, wind_speed) / 40.0)
	material_override.set_shader_parameter("amplitude", wind_speed / 200.0)
