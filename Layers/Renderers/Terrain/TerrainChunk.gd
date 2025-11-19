extends RenderChunk
class_name TerrainChunk

const low_ortho_resolution := 40
const low_landuse_resolution := 40
const low_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_10x10.obj")
const low_mesh_resolution := 10

const basic_load_distance := 5000.0
const basic_ortho_resolution := 200
const basic_landuse_resolution := 200
const basic_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_100x100.obj")
const basic_mesh_resolution := 100

const detailed_load_distance := 2000.0
const detailed_ortho_resolution := 1000
const detailed_landuse_resolution := 1000
const detailed_mesh := preload("res://Layers/Renderers/Terrain/lod_mesh_500x500.obj")
const detailed_mesh_resolution := 500

# Note: the mesh must always be scaled so that one unit within the mesh resolution corresponds to 1m
var mesh_resolution: int = 12345  # FIXME: required for override_decrease_quality(INF) to work when first instantiating chunks, but ugly
var ortho_resolution: int
var landuse_resolution: int

@export var load_detail_textures: bool = false
@export var load_fade_textures: bool = false
@export var always_load_landuse: bool = false

var height_layer: GeoRasterLayer
var texture_layer: GeoRasterLayer

var landuse_layer: GeoRasterLayer
var surface_height_layer: GeoRasterLayer

var mesh_to_apply := low_mesh

var current_heightmap
var current_heightmap_shape
var current_landuse
var current_surface_heightmap

var current_albedo_ground_textures
var current_normal_ground_textures
var current_specular_ground_textures
var current_ambient_ground_textures
var current_roughness_ground_textures


func rebuild_aabb(node):
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	node.set_custom_aabb(aabb)


func override_can_increase_quality(distance: float):
	return distance < basic_load_distance and mesh_resolution < basic_mesh_resolution \
			or distance < detailed_load_distance and mesh_resolution < detailed_mesh_resolution


func override_increase_quality(distance: float):
	if distance < detailed_load_distance and mesh_resolution < detailed_mesh_resolution:
		mesh_to_apply = detailed_mesh
		mesh_resolution = detailed_mesh_resolution
		ortho_resolution = detailed_ortho_resolution
		landuse_resolution = detailed_landuse_resolution
		return true
	elif distance < basic_load_distance and mesh_resolution < basic_mesh_resolution:
		mesh_to_apply = basic_mesh
		mesh_resolution = basic_mesh_resolution
		ortho_resolution = basic_ortho_resolution
		landuse_resolution = basic_landuse_resolution
		return true
	else:
		return false


func override_decrease_quality(distance: float):
	if distance > basic_load_distance and mesh_resolution > low_mesh_resolution:
		mesh_to_apply = low_mesh
		mesh_resolution = low_mesh_resolution
		ortho_resolution = low_ortho_resolution
		landuse_resolution = low_landuse_resolution
		return true
	elif distance > detailed_load_distance and mesh_resolution > basic_mesh_resolution:
		mesh_to_apply = basic_mesh
		mesh_resolution = basic_mesh_resolution
		ortho_resolution = basic_ortho_resolution
		landuse_resolution = basic_landuse_resolution
		return true
	else:
		return false


func override_build(center_x, center_y):
	var top_left_x = float(center_x - size / 2) - 1
	var top_left_y = float(center_y + size / 2) + 1
	
	# Heightmap
	var current_height_image = height_layer.get_image(
		top_left_x - 1,
		top_left_y + 1,
		size + 2,
		mesh_resolution + 1,
		0
	)
	
	if current_height_image.is_valid():
		current_heightmap = current_height_image.get_image_texture()
		current_heightmap_shape = current_height_image.get_shape_for_heightmap()
	
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
	$Mesh.mesh = mesh_to_apply
	
	rebuild_aabb($Mesh)
	
	scale.x = size / mesh_resolution
	scale.z = size / mesh_resolution
	
	$HeightmapCollider.position.x = 1.0 - (size / mesh_resolution) / scale.x 
	$HeightmapCollider.position.z = 1.0 - (size / mesh_resolution) / scale.x
	
	$Mesh.material_override.set_shader_parameter("size", size)
	
	if current_heightmap:
		$Mesh.material_override.set_shader_parameter("heightmap", current_heightmap)
		
		$HeightmapCollider/CollisionShape3D.shape = current_heightmap_shape
	
	var using_overlay = false
	
	if current_landuse:
		$Mesh.material_override.set_shader_parameter("landuse", current_landuse)
		$Mesh.material_override.set_shader_parameter("offset_noise", preload("res://Resources/Textures/ShaderUtil/rgb_solid_noise.png"))
		
		if mesh_resolution == detailed_mesh_resolution:
			if not has_node("LIDOverlayViewport"):
				add_child(preload("res://Layers/Renderers/Overlay/LIDOverlayViewport.tscn").instantiate())
			if not has_node("HeightOverlayViewport"):
				add_child(preload("res://Layers/Renderers/Overlay/HeightOverlayViewport.tscn").instantiate())
			
			using_overlay = true
			$Mesh.material_override.set_shader_parameter("use_landuse_overlay", true)
			$Mesh.material_override.set_shader_parameter("landuse_overlay", get_node("LIDOverlayViewport").get_texture())
			
			$Mesh.material_override.set_shader_parameter("use_height_overlay", true)
			$Mesh.material_override.set_shader_parameter("height_overlay", get_node("HeightOverlayViewport").get_texture())
		else:
			$Mesh.material_override.set_shader_parameter("use_landuse_overlay", false)
			$Mesh.material_override.set_shader_parameter("use_height_overlay", false)
			
			if has_node("LIDOverlayViewport"):
				get_node("LIDOverlayViewport").queue_free()
			if has_node("HeightOverlayViewport"):
				get_node("HeightOverlayViewport").queue_free()
	
	if current_surface_heightmap:
		$Mesh.material_override.set_shader_parameter("has_surface_heights", true)
		# Start applying surface heights at the point where vegetation stops
		$Mesh.material_override.set_shader_parameter("surface_heights_start_distance", Vegetation.get_max_extent() / 2.0)
		$Mesh.material_override.set_shader_parameter("surface_heightmap", current_surface_heightmap)
	
	var next_pass = $Mesh.material_override.next_pass
		
	while next_pass:
		next_pass.set_shader_parameter("heightmap", current_heightmap)
		next_pass.set_shader_parameter("surface_heightmap", current_surface_heightmap)
		next_pass.set_shader_parameter("landuse", current_landuse)
		
		if using_overlay:
			next_pass.set_shader_parameter("use_landuse_overlay", true)
			next_pass.set_shader_parameter("landuse_overlay", get_node("LIDOverlayViewport").get_texture())
			
			next_pass.set_shader_parameter("use_height_overlay", true)
			next_pass.set_shader_parameter("height_overlay", get_node("HeightOverlayViewport").get_texture())
		else:
			next_pass.set_shader_parameter("use_landuse_overlay", false)
			next_pass.set_shader_parameter("use_height_overlay", false)
		
		next_pass.set_shader_parameter("size", size)
		
		next_pass = next_pass.next_pass
