extends Spatial

onready var mesh_shader = get_node("GroundMesh").get_surface_material(0)
onready var water = get_node("WaterMesh")

func get_texture_from_server(filename):
	var texData = ServerConnection.getJson("http://127.0.0.1","/maps/?filename=%s" % [filename], 8000).values()
	var texBytes = PoolByteArray(texData)
    
	var img = Image.new()
	var tex = ImageTexture.new()
	
	img.load_png_from_buffer(texBytes)
	tex.create_from_image(img)
	
	return tex

func _ready():    
	mesh_shader.set_shader_param("tex", get_texture_from_server("water_test_texture.png"))
	mesh_shader.set_shader_param("heightmap", get_texture_from_server("water_test_height.png"))
	
	water.set_splatmap(get_texture_from_server("water_test_water.png"), 100, 1)