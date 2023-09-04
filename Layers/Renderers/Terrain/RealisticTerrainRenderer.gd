extends ChunkedLayerCompositionRenderer

var shader_material

func _setup_ground_textures():
	var texture_folders = [
		"Concrete", # to 120
		"Asphalt", # to 140
		"Lawn", # to 160
		"Gravel", # to 250
		"Riverbed", # to 260
		"Mud", # to 290
		"Glacier", # to 291
		"Rock", # to 300
		"Glade", # to 311
		"Foliage", # to 330
		"Moss", # to 340
		"Soil", # to 700
		"Meadow" # to 1000
	]
	
	var color_images = []
	var normal_images = []
	
	for texture_folder in texture_folders:
		var color_image = load("res://Resources/Textures/BaseGround/" + texture_folder + "/color.jpg")
		var normal_image = load("res://Resources/Textures/BaseGround/" + texture_folder + "/normal.jpg")
		
		color_image.generate_mipmaps()
		normal_image.generate_mipmaps()
		
		color_images.append(color_image)
		normal_images.append(normal_image)
	
	var texture_array = Texture2DArray.new()
	texture_array.create_from_images(color_images)
	
	# FIXME: We'd want to save and re-use this texture, but that doesn't work due to a Godot issue:
	#  https://github.com/godotengine/godot/issues/54202
	# ResourceSaver.save(texture_array, "res://Layers/Renderers/Terrain/Materials/GroundTextures.tres")
	
	var normal_array = Texture2DArray.new()
	normal_array.create_from_images(normal_images)
	
	shader_material = preload("res://Layers/Renderers/Terrain/Materials/TerrainShader.tres")
	shader_material.set_shader_parameter("ground_normals", normal_array)
	shader_material.set_shader_parameter("ground_textures", texture_array)


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.height_layer
	chunk.texture_layer = layer_composition.render_info.texture_layer
	chunk.landuse_layer = layer_composition.render_info.landuse_layer
	chunk.surface_height_layer = layer_composition.render_info.surface_height_layer
	
	chunk.get_node("Mesh").material_override = shader_material.duplicate()


func _ready():
	chunk_scene = preload("res://Layers/Renderers/Terrain/TerrainChunk.tscn")
	_setup_ground_textures()
	
	super._ready()


func _process(delta):
	super._process(delta)
	
	for decal in $Decals.get_children():
		decal.update(position_manager.center_node.position)
