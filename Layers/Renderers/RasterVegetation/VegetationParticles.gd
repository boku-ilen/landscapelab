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
var heightmap
var splatmap
var uv_offset_x := 0.0
var uv_offset_y := 0.0
var last_load_pos = Vector3.ZERO


func _ready():
	self.camera_facing_enabled = camera_facing_enabled
	Vegetation.connect("new_plant_extent_factor",Callable(self,"update_rows_spacing"))
	
	# Set static shader variables
	process_material.set_shader_parameter("row_ids", Vegetation.row_ids)
	process_material.set_shader_parameter("distribution_array", Vegetation.density_class_to_distribution_megatexture[density_class.id])
	
	material_override.set_shader_parameter("texture_map", Vegetation.plant_megatexture)
	
	set_rows_spacing_in_shader()


# Set the internal rows and spacing variables based checked the density_class and the given extent_factor.
func update_rows_spacing(extent_factor):
	var size = extent_factor * density_class.size_factor
	
	rows = floor(size * density_class.density_per_m)
	spacing = 1.0 / density_class.density_per_m
	
	set_rows(rows)
	set_spacing(spacing)
	
	update_aabb()
	
	$LIDOverlayViewport/LIDViewport/CameraRoot/LIDCamera.size = get_map_size()
	process_material.set_shader_parameter("splatmap_overlay", $LIDOverlayViewport/LIDViewport.get_texture())


func set_rows_spacing_in_shader():
	var size = Vector2(get_map_size(), get_map_size())
	process_material.set_shader_parameter("heightmap_size", size)
	material_override.set_shader_parameter("heightmap_size", size)
	
	process_material.set_shader_parameter("splatmap_size_meters", size.x)
	process_material.set_shader_parameter("dist_scale", 1.0 / spacing)


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
		material_override.set_shader_parameter("max_distance", rows * spacing / 2.0)
		
		set_rows_spacing_in_shader()


func set_spacing(new_spacing):
	spacing = new_spacing
	
	if process_material:
		process_material.set_shader_parameter("spacing", spacing)
		material_override.set_shader_parameter("max_distance", rows * spacing / 2.0)
		
		set_rows_spacing_in_shader()


# Return the size of the loaded GeoImage, which is at least as large as rows * spacing.
func get_map_size():
	return rows * spacing * 2.0


func complete_update(dhm_layer, splat_layer, world_x, world_y, new_uv_offset_x, new_uv_offset_y, clamped_pos_x, clamped_pos_y):
	var splat = texture_update(dhm_layer, splat_layer, world_x, world_y, new_uv_offset_x, new_uv_offset_y, clamped_pos_x, clamped_pos_y)


func texture_update(dhm_layer, splat_layer, world_x, world_y, new_uv_offset_x, new_uv_offset_y, clamped_pos_x, clamped_pos_y):
	var map_size = get_map_size()
	
	last_load_pos = Vector3(clamped_pos_x, 0.0, clamped_pos_y)
	
	var dhm = dhm_layer.get_image(
		float(world_x - map_size / 2),
		float(world_y + map_size / 2),
		float(map_size), 
		int(map_size),
		0
	)
	
	heightmap = dhm.get_image_texture()
	
	var splat = splat_layer.get_image(
		float(world_x - map_size / 2),
		float(world_y + map_size / 2),
		float(map_size), 
		int(map_size),
		0
	)
	
	splatmap = splat.get_image_texture()
	
	uv_offset_x = new_uv_offset_x
	uv_offset_y = new_uv_offset_y
	
	return splat


func apply_textures():
	$LIDOverlayViewport.position = last_load_pos
	
	process_material.set_shader_parameter("splatmap", splatmap)
	process_material.set_shader_parameter("heightmap", heightmap)
	process_material.set_shader_parameter("uv_offset", Vector2(uv_offset_x, uv_offset_y))


func apply_wind_speed(wind_speed):
	material_override.set_shader_parameter("speed", Vector2(wind_speed, wind_speed) / 160.0)
	material_override.set_shader_parameter("amplitude", wind_speed / 300.0)
