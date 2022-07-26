extends MeshInstance


export(float) var size = 100

export(int) var heightmap_resolution = 100
export(int) var texture_resolution = 1000

var position_x
var position_y

var height_layer
var texture_layer

# Data shading specific
var is_color_shaded
var min_color: Color
var max_color: Color

var current_heightmap
var current_texture

signal updated_data


func _ready():
	visible = false


# TODO: Use this instead of the extra cull margin; can't get it to work properly atm
func rebuild_aabb():
	var aabb = AABB(Vector3.ZERO, Vector3(size / 2, 100000, size / 2))
	set_custom_aabb(aabb)


func build():
	var top_left_x = position_x - size / 2
	var top_left_y = position_y + size / 2
	
	scale.x = size / mesh.size.x
	scale.z = size / mesh.size.y
	
	# Heightmap
	var current_height_image = height_layer.get_image(
		top_left_x,
		top_left_y,
		size,
		heightmap_resolution,
		1
	)
	
	if current_height_image.is_valid():
		current_heightmap = current_height_image.get_image_texture()
	
	# Texture
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
			heightmap_resolution,
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

func apply_textures():
	material_override.set_shader_param("size", size)
	
	if current_heightmap:
		material_override.set_shader_param("heightmap", current_heightmap)
		
		if has_node("CollisionMeshCreator"):
			$CollisionMeshCreator.create_mesh(current_heightmap, size)

		if has_node("ExtraLOD"):
			$ExtraLOD.apply_textures(current_heightmap, current_surface_heightmap, current_landuse)
	
	if not is_color_shaded:
		if not is_inner:
			material_override.set_shader_param("has_hole", true)
		
		if current_texture:
			material_override.set_shader_param("orthophoto", current_texture)
		
		if current_landuse:
			material_override.set_shader_param("landuse", current_landuse)
			material_override.set_shader_param("offset_noise", preload("res://Resources/Textures/ShaderUtil/rgb_solid_noise.png"))
			
			if not always_load_landuse:
				# always_load_landuse doesn't load any detail textures (it just provides the landuse data to ExtraLODs)
				# so in that case, don't apply the data to the shader
				# FIXME: Make this more clear in the variable names
				material_override.set_shader_param("has_landuse", true)
		
		if current_surface_heightmap:
			material_override.set_shader_param("has_surface_heights", true)
			# Start applying surface heights at the point where vegetation stops
			material_override.set_shader_param("surface_heights_start_distance", Vegetation.get_max_extent() / 2.0)
			material_override.set_shader_param("surface_heightmap", current_surface_heightmap)
		
		if current_metadata_map:
			material_override.set_shader_param("metadata", current_metadata_map)
		
		if current_albedo_ground_textures:
			material_override.set_shader_param("uses_detail_textures", true)
			material_override.set_shader_param("albedo_tex", current_albedo_ground_textures)
			material_override.set_shader_param("normal_tex", current_normal_ground_textures)
			material_override.set_shader_param("ambient_tex", current_ambient_ground_textures)
			material_override.set_shader_param("specular_tex", current_specular_ground_textures)
			material_override.set_shader_param("roughness_tex", current_roughness_ground_textures)
		
		if current_albedo_fade_textures:
			material_override.set_shader_param("uses_distance_textures", true)
			material_override.set_shader_param("distance_tex", current_albedo_fade_textures)
			material_override.set_shader_param("distance_normals", current_normal_fade_textures)
			material_override.set_shader_param("distance_tex_switch_distance", Vegetation.plant_extent_factor * 5.0)
			material_override.set_shader_param("fade_transition_space", Vegetation.plant_extent_factor * 2.0)
	else:
		if current_texture:
			material_override.set_shader_param("tex", current_texture)
	
	visible = true
