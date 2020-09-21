extends MeshInstance


export(Mesh) var inner_mesh
export(Mesh) var ring_mesh
export(float) var mesh_size

export(bool) var is_inner

export(float) var size = 100

var position_x
var position_y

var height_layer
var texture_layer

var current_heightmap
var current_texture


func _ready():
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
	
	# TODO: We need new objects here due to being in a thread. Solve this with a "copy" function instead.
	current_heightmap = Geodot.get_dataset("GPKG:/home/karl/Downloads/LL_base.gpkg:dhm").get_raster_layer("").get_image(
		top_left_x,
		top_left_y,
		size,
		100,
		1
	).get_image_texture()
	current_texture = Geodot.get_dataset("GPKG:/home/karl/Downloads/LL_base.gpkg:ortho").get_raster_layer("").get_image(
		top_left_x,
		top_left_y,
		size,
		1000,
		1
	).get_image_texture()


func apply_textures():
	material_override.set_shader_param("heights", current_heightmap)
	material_override.set_shader_param("tex", current_texture)
