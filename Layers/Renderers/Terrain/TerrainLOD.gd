extends MeshInstance


export(Mesh) var inner_mesh
export(Mesh) var ring_mesh
export(float) var mesh_size

export(bool) var is_inner

export(float) var size = 100

export(int) var heightmap_resolution = 100
export(int) var ortho_resolution = 1000

var position_x
var position_y

var height_layer
var texture_layer

var current_heightmap_raw
var current_heightmap
var current_texture

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
	
	var current_height_image = height_layer.get_image(
		top_left_x,
		top_left_y,
		size,
		heightmap_resolution,
		1
	)
	
	if current_height_image.is_valid():
		current_heightmap = current_height_image.get_image_texture()
		current_heightmap_raw = current_height_image.get_image()
	
	
	var current_ortho_image = texture_layer.get_image(
		top_left_x,
		top_left_y,
		size,
		ortho_resolution,
		1
	)
	
	if current_ortho_image.is_valid():
		current_texture = current_ortho_image.get_image_texture()


func apply_textures():
	if current_heightmap and current_texture:
		material_override.set_shader_param("heights", current_heightmap)
		material_override.set_shader_param("tex", current_texture)
		
		visible = true
		
		if has_node("CollisionMeshCreator"):
			$CollisionMeshCreator.create_mesh(current_heightmap, size)
