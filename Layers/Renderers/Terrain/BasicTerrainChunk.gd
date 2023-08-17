extends MeshInstance3D
class_name BasicTerrainChunk

# Note: the mesh must always be scaled so that one unit within the mesh resolution corresponds to 1m
@export var mesh_resolution: int = 100
@export var size: float = 100

@export var texture_resolution: int = 1000

var position_diff_x
var position_diff_z

var height_layer: GeoRasterLayer
var texture_layer: GeoRasterLayer

# Data shading specific
var is_color_shaded
var min_color: Color
var max_color: Color

# Terrain
var current_heightmap
var current_heightmap_shape
var current_normalmap
var current_texture

var changed = false

signal updated_data


func _ready():
	visible = false


func rebuild_aabb():
	var aabb = AABB(global_transform.origin - position - Vector3(size / 2.0, 0.0, size / 2.0), Vector3(size, 100000, size))
	set_custom_aabb(aabb)


func build(center_x, center_y):
	var top_left_x = float(center_x - size / 2)
	var top_left_y = float(center_y + size / 2)
	
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
		current_normalmap = current_height_image.get_normalmap_texture_for_heightmap(10.0)
		current_heightmap_shape = current_height_image.get_shape_for_heightmap()
	
	# Texture2D
	if texture_layer:
		var current_ortho_image = texture_layer.get_image(
			top_left_x,
			top_left_y,
			size,
			texture_resolution,
			1
		)
		
		if current_ortho_image.is_valid():
			current_texture = current_ortho_image.get_image_texture()
	
	changed = true


func apply_textures():
	rebuild_aabb()
	
	material_override.set_shader_parameter("size", size)
	
	if current_heightmap:
		material_override.set_shader_parameter("heightmap", current_heightmap)
		material_override.set_shader_parameter("normalmap", current_normalmap)
		
		$HeightmapCollider/CollisionShape3D.shape = current_heightmap_shape
	
	if not is_color_shaded:
		if current_texture:
			material_override.set_shader_parameter("orthophoto", current_texture)
	else:
		if current_texture:
			material_override.set_shader_parameter("tex", current_texture)
	
	scale.x = size / mesh_resolution
	scale.z = size / mesh_resolution
	
	$HeightmapCollider.position.x = 1.0 - (size / mesh_resolution) / scale.x 
	$HeightmapCollider.position.z = 1.0 - (size / mesh_resolution) / scale.x
	
	visible = true
	changed = false
