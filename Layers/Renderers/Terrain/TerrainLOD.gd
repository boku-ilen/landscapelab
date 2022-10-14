extends MeshInstance3D

# Note: the mesh must always be scaled so that one unit within the mesh resolution corresponds to 1m
@export var mesh_resolution: float = 100
@export var size: float = 100

@export var ortho_resolution: int = 1000
@export var landuse_resolution: int = 100

@export var load_detail_textures: bool = false
@export var load_fade_textures: bool = false
@export var always_load_landuse: bool = false

const MAX_GROUPS = 6

var position_diff_x
var position_diff_z

var height_layer
var texture_layer

# Data shading specific
var is_color_shaded
var min_color: Color
var max_color: Color

# Terrain specific
var landuse_layer
var surface_height_layer

var current_heightmap
var current_normalmap
var current_texture
var current_landuse
var current_surface_heightmap
var current_metadata_map

var current_albedo_ground_textures
var current_normal_ground_textures
var current_specular_ground_textures
var current_ambient_ground_textures
var current_roughness_ground_textures

var current_albedo_fade_textures
var current_normal_fade_textures

var changed = false

signal updated_data


func _ready():
	visible = false


func rebuild_aabb():
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	set_custom_aabb(aabb)


func build(center_x, center_y):
	var top_left_x = center_x - size / 2 
	var top_left_y = center_y + size / 2 
	
	scale.x = size / mesh_resolution
	scale.z = size / mesh_resolution
	
	$HeightmapCollider.position.x = 1.0 - (size / mesh_resolution) / scale.x 
	$HeightmapCollider.position.z = 1.0 - (size / mesh_resolution) / scale.x
	
	# Heightmap
	var sample_rate = size / mesh_resolution
	
	var current_height_image = height_layer.get_image(
		top_left_x - sample_rate / 2.0,
		top_left_y - sample_rate / 2.0,
		size + sample_rate,
		mesh_resolution + 1,
		0
	)
	
	if current_height_image.is_valid():
		current_heightmap = current_height_image.get_image_texture()
		current_normalmap = current_height_image.get_normalmap_texture_for_heightmap(35.0 / size)
	
	# Texture2D
	if texture_layer:
		var current_ortho_image = texture_layer.get_image(
			top_left_x,
			top_left_y,
			size,
			ortho_resolution,
			1
		)
		
		if current_ortho_image.is_valid():
			current_texture = current_ortho_image.get_image_texture()
	
	var current_landuse_image = landuse_layer.get_image(
		top_left_x,
		top_left_y,
		size,
		landuse_resolution,
		0
	)
	
	if current_landuse_image.is_valid():
		current_landuse = current_landuse_image.get_image_texture()
	
	# Surface Height
	if surface_height_layer:
		var current_surface_height_image = surface_height_layer.get_image(
			top_left_x,
			top_left_y,
			size,
			mesh_resolution,
			1
		)
		
		if current_surface_height_image.is_valid():
			current_surface_heightmap = current_surface_height_image.get_image_texture()
	
	if landuse_layer and (always_load_landuse or load_detail_textures or load_fade_textures):
		if load_detail_textures or load_fade_textures:
			var most_common_groups = current_landuse_image.get_most_common(MAX_GROUPS)
			var group_array = Vegetation.get_group_array_for_ids(most_common_groups)
			
			current_metadata_map = Vegetation.get_metadata_map(most_common_groups)
			
			if load_detail_textures:
				current_albedo_ground_textures = Vegetation.get_ground_sheet_texture(group_array, "albedo")
				current_normal_ground_textures = Vegetation.get_ground_sheet_texture(group_array, "normal")
				current_specular_ground_textures = Vegetation.get_ground_sheet_texture(group_array, "specular")
				current_ambient_ground_textures = Vegetation.get_ground_sheet_texture(group_array, "ambient")
				current_roughness_ground_textures = Vegetation.get_ground_sheet_texture(group_array, "roughness")
			
			if load_fade_textures:
				current_albedo_fade_textures = Vegetation.get_fade_sheet_texture(group_array, "albedo")
				current_normal_fade_textures = Vegetation.get_fade_sheet_texture(group_array, "normal")
	
	changed = true

func apply_textures():
	rebuild_aabb()
	
	material_override.set_shader_parameter("size", size)
	
	if current_heightmap:
		material_override.set_shader_parameter("heightmap", current_heightmap)
		material_override.set_shader_parameter("normalmap", current_normalmap)
		
		# Create a float array for the heightmap collider to use as a heightmap
		var heightmap_image = current_heightmap.get_image()
		heightmap_image.convert(Image.FORMAT_RF)
		$HeightmapCollider/CollisionShape3D.shape = HeightMapShape3D.new()
		$HeightmapCollider/CollisionShape3D.shape.map_width = heightmap_image.get_width()
		$HeightmapCollider/CollisionShape3D.shape.map_depth = heightmap_image.get_height()

		# Assign the heights using the image's raw data.
		# Because the format matches, this is straightforward
		var float_array = PackedFloat32Array()
		float_array.resize(heightmap_image.get_width() * heightmap_image.get_height())
		var i = 0
		for y in heightmap_image.get_height():
			for x in heightmap_image.get_width():
				float_array[i] = heightmap_image.get_pixel(x, y).r
				i += 1
		$HeightmapCollider/CollisionShape3D.shape.map_data = float_array
		
		for child in get_children():
			if child is ExtraLOD:
				child.apply_textures(current_heightmap, current_surface_heightmap, current_landuse)
	
	if not is_color_shaded:
		if current_texture:
			material_override.set_shader_parameter("orthophoto", current_texture)
		
		if current_landuse:
			material_override.set_shader_parameter("landuse", current_landuse)
			material_override.set_shader_parameter("offset_noise", preload("res://Resources/Textures/ShaderUtil/rgb_solid_noise.png"))
			
			if not always_load_landuse:
				# always_load_landuse doesn't load any detail textures (it just provides the landuse data to ExtraLODs)
				# so in that case, don't apply the data to the shader
				# FIXME: Make this more clear in the variable names
				material_override.set_shader_parameter("has_landuse", true)
		
		if current_surface_heightmap:
			material_override.set_shader_parameter("has_surface_heights", true)
			# Start applying surface heights at the point where vegetation stops
			material_override.set_shader_parameter("surface_heights_start_distance", Vegetation.get_max_extent() / 2.0)
			material_override.set_shader_parameter("surface_heightmap", current_surface_heightmap)
		
		if current_metadata_map:
			material_override.set_shader_parameter("metadata", current_metadata_map)
		
		if current_albedo_ground_textures:
			material_override.set_shader_parameter("uses_detail_textures", true)
			material_override.set_shader_parameter("albedo_tex", current_albedo_ground_textures)
			material_override.set_shader_parameter("normal_tex", current_normal_ground_textures)
			material_override.set_shader_parameter("ambient_tex", current_ambient_ground_textures)
			material_override.set_shader_parameter("specular_tex", current_specular_ground_textures)
			material_override.set_shader_parameter("roughness_tex", current_roughness_ground_textures)
		
		if current_albedo_fade_textures:
			material_override.set_shader_parameter("uses_distance_textures", true)
			material_override.set_shader_parameter("distance_tex", current_albedo_fade_textures)
			material_override.set_shader_parameter("distance_normals", current_normal_fade_textures)
			material_override.set_shader_parameter("distance_tex_switch_distance", Vegetation.plant_extent_factor * 5.0)
			material_override.set_shader_parameter("fade_transition_space", Vegetation.plant_extent_factor * 2.0)
	else:
		if current_texture:
			material_override.set_shader_parameter("tex", current_texture)
	
	visible = true
	changed = false
