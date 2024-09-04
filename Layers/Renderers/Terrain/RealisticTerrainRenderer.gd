extends ChunkedLayerCompositionRenderer

var weather_manager: WeatherManager :
	get:
		return weather_manager
	set(new_weather_manager):
		weather_manager = new_weather_manager

		weather_manager.connect("wind_speed_changed",Callable(self,"_on_wind_speed_changed"))
		_on_wind_speed_changed(weather_manager.wind_speed)

var shader_material = preload("res://Layers/Renderers/Terrain/Materials/TerrainShader.tres")

func _setup_ground_textures():
	var texture_folders = [
		"Asphalt", # 1 Sealed
		"Gravel", # 2 Semi-Sealed
		"Lawn", # 3 Mixed Urban TODO: Should be "Lawn", but not for Pantelleria - use project-specific settings?
		"Rock", # 4 Open Ground TODO: Could also be "Rock" depending on the project
		"Glacier", # 5 Snow and Ice
		"Riverbed", # 6 Water
		"Meadow", # 7 Grassland, Pastures, Fallows
		"Foliage", # 8 Shrubs and Forests
		"Glade", # 9 Agroforest and Permanent Cultures
		"SoilGreen", # 10 Agriculture
	]
	
	var color_images = []
	var normal_images = []
	var displacement_images = []
	
	for texture_folder in texture_folders:
		var color_image = load("res://Resources/Textures/BaseGround/" + texture_folder + "/color.jpg")
		var normal_image = load("res://Resources/Textures/BaseGround/" + texture_folder + "/normal.jpg")
		var displacement_image = load("res://Resources/Textures/BaseGround/" + texture_folder + "/displacement.jpg")
		
		color_image.generate_mipmaps()
		normal_image.generate_mipmaps()
		displacement_image.generate_mipmaps()
		
		color_images.append(color_image)
		normal_images.append(normal_image)
		displacement_images.append(displacement_image)
	
	var texture_array = Texture2DArray.new()
	texture_array.create_from_images(color_images)
	
	# FIXME: We'd want to save and re-use this texture, but that doesn't work due to a Godot issue:
	#  https://github.com/godotengine/godot/issues/54202
	# ResourceSaver.save(texture_array, "res://Layers/Renderers/Terrain/Materials/GroundTextures.tres")
	
	var normal_array = Texture2DArray.new()
	normal_array.create_from_images(normal_images)
	
	var displacement_array = Texture2DArray.new()
	displacement_array.create_from_images(displacement_images)
	
	shader_material.set_shader_parameter("ground_normals", normal_array)
	shader_material.set_shader_parameter("ground_textures", texture_array)
	shader_material.set_shader_parameter("ground_displacement", displacement_array)


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.height_layer
	chunk.texture_layer = layer_composition.render_info.texture_layer
	chunk.landuse_layer = layer_composition.render_info.landuse_layer
	chunk.surface_height_layer = layer_composition.render_info.surface_height_layer
	
	chunk.get_node("Mesh").material_override = shader_material.duplicate()


func _ready():
	_setup_ground_textures()
	$DetailMesh.material_override = shader_material.duplicate()
	
	super._ready()


func _process(delta):
	super._process(delta)
	
	for decal in $Decals.get_children():
		decal.update(position_manager.center_node.position)


func _on_wind_speed_changed(new_wind_speed):
	for chunk in chunks:
		chunk.get_node("Water").material_override.set_shader_parameter("wind_speed", new_wind_speed)
