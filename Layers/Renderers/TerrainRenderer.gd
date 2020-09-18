extends LayerRenderer


# TODO:
# Instead of heightmap dataset, use `layer` variable.
# Instead of ortho dataset, use reference to other layer - coming from the `layer`.
# Get position from somewhere else

onready var mesh = get_node("TerrainMesh")

var heightmap_data_path = "/media/karl/loda1/geodata/wien/test_dhm.tif"
var ortho_data_path = "/media/karl/loda1/geodata/wien/test_ortho.jpg"

var tile_size_meters = 1000
var tile_size_pixels = 2000


# Called when the node enters the scene tree for the first time.
func _ready():
	var pos_x = -6131.50
	var pos_y = 336222.39
	
	var heightmap_data = layer.fields["heights"]
	var ortho_data = layer.fields["texture"]
	
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
