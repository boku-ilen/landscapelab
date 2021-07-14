extends MeshInstance


export(Mesh) var inner_mesh
export(Mesh) var ring_mesh
export(float) var mesh_size

export(bool) var is_inner

export(float) var size = 100

export(int) var heightmap_resolution = 100
export(int) var ortho_resolution = 1000
export(int) var landuse_resolution = 100

var position_x
var position_y

var height_layer
var texture_layer
var landuse_layer
var surface_height_layer

var current_heightmap
var current_texture
var current_landuse
var current_surface_heightmap

signal updated_data


func _ready():
	visible = false
	
	if is_inner:
		mesh = inner_mesh
	else:
		mesh = ring_mesh


# TODO: Use this instead of the extra cull margin; can't get it to work properly atm
func rebuild_aabb():
	var aabb = AABB(Vector3.ZERO, Vector3(size / 2, 100000, size / 2))
	set_custom_aabb(aabb)


func build():
	var top_left_x = position_x - size / 2
	var top_left_y = position_y + size / 2
	
	scale.x = size / mesh_size
	scale.z = size / mesh_size
	
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
	
	# Land Use
	if landuse_layer:
		var current_landuse_image = landuse_layer.get_image(
			top_left_x,
			top_left_y,
			size,
			landuse_resolution,
			1
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


func apply_textures():
	if current_heightmap:
		material_override.set_shader_param("heightmap", current_heightmap)
	
	if current_texture:
		material_override.set_shader_param("orthophoto", current_texture)
	
	if current_landuse:
		material_override.set_shader_param("landuse", current_landuse)
	
	if current_surface_heightmap:
		material_override.set_shader_param("surface_heightmap", current_surface_heightmap)
		
	visible = true
	
	if has_node("CollisionMeshCreator"):
		$CollisionMeshCreator.create_mesh(current_heightmap, size)
