extends RenderChunk
class_name TerrainChunk

const basic_ortho_resolution := 100
const basic_landuse_resolution := 100
const basic_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_100x100.obj")
const basic_mesh_resolution := 100

const detailed_load_distance := 2000.0
const detailed_ortho_resolution := 2000
const detailed_landuse_resolution := 1000
const detailed_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_500x500.obj")
const detailed_mesh_resolution := 500

# Note: the mesh must always be scaled so that one unit within the mesh resolution corresponds to 1m
var mesh_resolution: int
var ortho_resolution: int
var landuse_resolution: int

@export var load_detail_textures: bool = false
@export var load_fade_textures: bool = false
@export var always_load_landuse: bool = false

var height_layer: GeoRasterLayer
var texture_layer: GeoRasterLayer

var landuse_layer: GeoRasterLayer
var surface_height_layer: GeoRasterLayer

var mesh_to_apply

var current_heightmap
var current_heightmap_shape
var current_normalmap
var current_texture
var current_landuse
var current_surface_heightmap

var current_albedo_ground_textures
var current_normal_ground_textures
var current_specular_ground_textures
var current_ambient_ground_textures
var current_roughness_ground_textures

var terraforming_texture: TerraformingTexture


func rebuild_aabb():
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	$Mesh.set_custom_aabb(aabb)


func override_upgrade():
	mesh_to_apply = detailed_mesh
	mesh_resolution = detailed_mesh_resolution
	ortho_resolution = detailed_ortho_resolution
	landuse_resolution = detailed_landuse_resolution


func override_downgrade():
	mesh_to_apply = basic_mesh
	mesh_resolution = basic_mesh_resolution
	ortho_resolution = basic_ortho_resolution
	landuse_resolution = basic_landuse_resolution


func override_build(center_x, center_y):
	# Create a new TerraformingTexture for this chunk
	#terraforming_texture = TerraformingTexture.new(201)
	
	var top_left_x = float(center_x - size / 2)
	var top_left_y = float(center_y + size / 2)
	
	# Heightmap
	var sample_rate = size / mesh_resolution
	
	var current_height_image = height_layer.get_image(
		top_left_x - sample_rate / 2.0,
		top_left_y + sample_rate / 2.0,
		size + sample_rate,
		mesh_resolution + 1,
		0
	)
	
	if current_height_image.is_valid():
		current_heightmap = current_height_image.get_image_texture()
		current_normalmap = current_height_image.get_normalmap_texture_for_heightmap(10.0)
		current_heightmap_shape = current_height_image.get_shape_for_heightmap()
	
	# Orthophoto
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
	
	# Land use
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


func override_apply():
	rebuild_aabb()
	
	$Mesh.mesh = mesh_to_apply
	
	scale.x = size / mesh_resolution
	scale.z = size / mesh_resolution
	
	$HeightmapCollider.position.x = 1.0 - (size / mesh_resolution) / scale.x 
	$HeightmapCollider.position.z = 1.0 - (size / mesh_resolution) / scale.x
	
	$Mesh.material_override.set_shader_parameter("size", size)
	
	if current_heightmap:
		$Mesh.material_override.set_shader_parameter("heightmap", current_heightmap)
		$Mesh.material_override.set_shader_parameter("normalmap", current_normalmap)
		
		$HeightmapCollider/CollisionShape3D.shape = current_heightmap_shape
		
		for child in get_children():
			if child is ExtraLOD:
				child.apply_textures(current_heightmap, current_surface_heightmap, current_landuse)
	
	if current_texture:
		$Mesh.material_override.set_shader_parameter("orthophoto", current_texture)
	
	if current_landuse:
		$Mesh.material_override.set_shader_parameter("landuse", current_landuse)
		$Mesh.material_override.set_shader_parameter("offset_noise", preload("res://Resources/Textures/ShaderUtil/rgb_solid_noise.png"))
		$Mesh.material_override.set_shader_parameter("has_landuse", true)
	
	if current_surface_heightmap:
		$Mesh.material_override.set_shader_parameter("has_surface_heights", true)
		# Start applying surface heights at the point where vegetation stops
		$Mesh.material_override.set_shader_parameter("surface_heights_start_distance", Vegetation.get_max_extent() / 2.0)
		$Mesh.material_override.set_shader_parameter("surface_heightmap", current_surface_heightmap)


func apply_terraforming_texture() -> void:
	$Mesh.material_override.set_shader_parameter("has_terraforming_texture", true)
	$Mesh.material_override.set_shader_parameter("terraforming_texture", terraforming_texture.texture)
	$Mesh.material_override.set_shader_parameter("terraforming_weights", terraforming_texture.weights)
