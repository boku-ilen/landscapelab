extends LayerRenderer


# TODO:
# Instead of heightmap dataset, use `layer` variable.
# Instead of ortho dataset, use reference to other layer - coming from the `layer`.
# Get position from somewhere else

onready var mesh = get_node("TerrainMesh")

var tile_size_meters = 1000
var tile_size_pixels = 2000


# Called when the node enters the scene tree for the first time.
func _ready():
	var pos_x = 420776.711
	var pos_y = 453197.501
	
	var heightmap_data = layer.render_info.height_layer
	var ortho_data = layer.render_info.texture_layer
	
	var img = heightmap_data.get_image(
		pos_x,
		pos_y,
		tile_size_meters,
		500,
		1
	)
	var ortho = ortho_data.get_image(
		pos_x,
		pos_y,
		tile_size_meters,
		2000,
		1
	)
	
	mesh.get_surface_material(0).set_shader_param("heights", img.get_image_texture())
	mesh.get_surface_material(0).set_shader_param("tex", ortho.get_image_texture())
