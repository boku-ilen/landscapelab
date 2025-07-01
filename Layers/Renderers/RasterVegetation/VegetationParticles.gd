extends GPUParticles3D


# With 4 rows and a spacing of 0.5, plants are drawn within a 2x2 area.
@export var rows = 4
@export var spacing = 1.0

var waiting_for_update := false

# Density class of this plant renderer -- influences the density of the rendered particles.
var density_class: DensityClass :
	get:
		return density_class
	set(new_density_class):
		density_class = new_density_class
		
		update_rows_spacing(get_plant_extent_factor())

@export var offset: Vector2 = Vector2.ZERO

var current_offset_from_shifting = Vector2.ZERO
var time_passed = 0
var previous_origin

# Data
var heightmap
var splatmap
var uv_offset_x := 0.0
var uv_offset_y := 0.0
var last_load_pos = Vector3.ZERO


func _ready():
	Vegetation.new_plant_extent_factor.connect(update_rows_spacing)
	Vegetation.new_data.connect(_on_vegetation_data_update)
	
	set_mesh(density_class.mesh)
	material_override.set_shader_parameter("is_billboard", density_class.is_billboard)
	
	# Set static shader variables
	process_material.set_shader_parameter("row_ids", Vegetation.row_ids[density_class.id])
	process_material.set_shader_parameter("distribution_array", Vegetation.density_class_to_distribution_megatexture[density_class.id])
	material_override.set_shader_parameter("texture_map", Vegetation.plant_megatexture)
	
	set_rows_spacing_in_shader()


func _on_vegetation_data_update():
	process_material.set_shader_parameter("row_ids", Vegetation.row_ids[density_class.id])
	process_material.set_shader_parameter("distribution_array", Vegetation.density_class_to_distribution_megatexture[density_class.id])
	material_override.set_shader_parameter("texture_map", Vegetation.plant_megatexture)


func get_plant_extent_factor():
	var extent_scale = 1.0
	if "Shrubs" in density_class.name: extent_scale = 6.0  # FIXME: Use config for this
	return Vegetation.plant_extent_factor * extent_scale


# Set the internal rows and spacing variables based checked the density_class and the given extent_factor.
func update_rows_spacing(extent_factor):
	var size = extent_factor# * density_class.size_factor
	
	rows = floor(size * density_class.density_per_m)
	spacing = (1.0 / density_class.density_per_m) * 0.995037196291074
	
	set_rows(rows)
	set_spacing(spacing)
	
	update_aabb()
	
	$LIDOverlayViewport/LIDViewport/CameraRoot/LIDCamera.size = get_map_size()
	$LIDOverlayViewport/LIDViewport.size = Vector2(get_map_size() / 0.995037196291074, get_map_size() / 0.995037196291074)
	process_material.set_shader_parameter("splatmap_overlay", $LIDOverlayViewport/LIDViewport.get_texture())
	
	$HeightOverlayViewport/LIDViewport/CameraRoot/LIDCamera.size = get_map_size()
	$HeightOverlayViewport/LIDViewport.size = Vector2(get_map_size() / 0.995037196291074, get_map_size() / 0.995037196291074)
	process_material.set_shader_parameter("height_overlay", $HeightOverlayViewport/LIDViewport.get_texture())


func set_rows_spacing_in_shader():
	var size = Vector2(get_map_size(), get_map_size())
	process_material.set_shader_parameter("heightmap_size", size)
	
	process_material.set_shader_parameter("splatmap_size_meters", size.x)
	process_material.set_shader_parameter("dist_scale", 1.0 / spacing)


func set_mesh(new_mesh):
	draw_pass_1 = new_mesh


# Updates the visibility AABB which is used for culling.
func update_aabb():
	var size = rows * spacing
	visibility_aabb = AABB(Vector3(-0.5 * size, -1000.0, -0.5 * size), Vector3(size, 10000.0, size))


func set_rows(new_rows):
	rows = new_rows
	amount = rows * rows
	
	if process_material:
		process_material.set_shader_parameter("rows", rows)
		material_override.set_shader_parameter("max_distance", get_plant_extent_factor() / 2.0)
		
		set_rows_spacing_in_shader()


func set_spacing(new_spacing):
	spacing = new_spacing
	
	if process_material:
		process_material.set_shader_parameter("spacing", spacing)
		material_override.set_shader_parameter("max_distance", get_plant_extent_factor() / 2.0)
		
		set_rows_spacing_in_shader()


# Return the size of the loaded GeoImage, which is at least as large as rows * spacing.
func get_map_size():
	return rows * spacing * 2.0


func complete_update(dhm_layer, splat_layer, center, center_position):
	# Clamp to the spacing in order to have a matching grid
	var clamped_pos_x = center_position.x - fposmod(center_position.x, 0.995037196291074)
	var clamped_pos_y = center_position.z + (0.995037196291074 - fposmod(center_position.z, 0.995037196291074))
	
	var world_position = [
		center[0] + clamped_pos_x,
		center[1] - clamped_pos_y
	]
	
	uv_offset_x = clamped_pos_x
	uv_offset_y = clamped_pos_y
	
	var map_size = get_map_size()
	
	last_load_pos = Vector3(clamped_pos_x, 0.0, clamped_pos_y)
	
	var dhm = dhm_layer.get_image(
		float(world_position[0] - map_size / 2),
		float(world_position[1] + map_size / 2),
		float(map_size), 
		int(map_size / 0.995037196291074),
		0
	)
	
	heightmap = dhm.get_image_texture()
	
	var splat = splat_layer.get_image(
		float(world_position[0] - map_size / 2),
		float(world_position[1] + map_size / 2),
		float(map_size), 
		int(map_size / 0.995037196291074),
		0
	)
	
	splatmap = splat.get_image_texture()


func apply_textures():
	$LIDOverlayViewport.position = last_load_pos
	$HeightOverlayViewport.position = last_load_pos
	
	# Wait for the LIDOverlayViewport to render
	await get_tree().process_frame
	await get_tree().process_frame
	
	process_material.set_shader_parameter("splatmap", splatmap)
	process_material.set_shader_parameter("heightmap", heightmap)
	process_material.set_shader_parameter("uv_offset", Vector2(uv_offset_x, uv_offset_y))
	
	restart()


func apply_wind(wind_force):
	material_override.set_shader_parameter("speed", wind_force)
