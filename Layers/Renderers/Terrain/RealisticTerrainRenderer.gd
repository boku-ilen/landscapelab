extends ChunkedLayerCompositionRenderer

var weather_manager: WeatherManager :
	get:
		return weather_manager
	set(new_weather_manager):
		weather_manager = new_weather_manager

		weather_manager.connect("wind_speed_changed",Callable(self,"_on_wind_speed_changed"))
		_on_wind_speed_changed(weather_manager.wind_speed)

var shader_material = preload("res://Layers/Renderers/Terrain/Materials/TerrainShader.tres")
var water_material = preload("res://addons/water/Water.tres")
var fake_plant_material = preload("res://Layers/Renderers/Terrain/Materials/FakePlantMaterial.tres")

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
	chunk.get_node("Mesh").material_override.next_pass = water_material.duplicate()
	chunk.get_node("Mesh").material_override.next_pass.next_pass = fake_plant_material.duplicate()
	
	# Set static shader variables
	chunk.get_node("Mesh").material_override.next_pass.next_pass.set_shader_parameter("row_ids", Vegetation.row_ids[1])
	chunk.get_node("Mesh").material_override.next_pass.next_pass.set_shader_parameter("distribution_array", Vegetation.density_class_to_distribution_megatexture[1])
	chunk.get_node("Mesh").material_override.next_pass.next_pass.set_shader_parameter("texture_map", Vegetation.plant_megatexture)
	
	chunk.get_node("Mesh").material_override.next_pass.next_pass.next_pass = fake_plant_material.duplicate()
	
	# FIXME: Try to combine all density classes into one shader
	
	# Set static shader variables
	chunk.get_node("Mesh").material_override.next_pass.next_pass.next_pass.set_shader_parameter("row_ids", Vegetation.row_ids[6])
	chunk.get_node("Mesh").material_override.next_pass.next_pass.next_pass.set_shader_parameter("distribution_array", Vegetation.density_class_to_distribution_megatexture[6])
	chunk.get_node("Mesh").material_override.next_pass.next_pass.next_pass.set_shader_parameter("texture_map", Vegetation.plant_megatexture)
	
	chunk.get_node("Mesh").material_override.next_pass.next_pass.next_pass.next_pass = fake_plant_material.duplicate()



func _ready():
	_setup_ground_textures()
	$DetailMesh.material_override = shader_material.duplicate()
	
	super._ready()


func full_load():
	super.full_load()
	if  layer_composition.render_info.water_color == null \
		or not "surface_color" in layer_composition.render_info.water_color \
		or not "depth_color" in layer_composition.render_info.water_color:
		return
	
	var surface_color = _array_to_color(layer_composition.render_info.water_color["surface_color"])
	var depth_color = _array_to_color(layer_composition.render_info.water_color["depth_color"])
	_apply_water_color(surface_color, depth_color)


func _apply_water_color(surface_color: Color, depth_color: Color) -> void:
	for chunk in chunks:
		chunk.get_node("Mesh").material_override.next_pass.set_shader_parameter(
			"surface_color", surface_color)
		chunk.get_node("Mesh").material_override.next_pass.set_shader_parameter(
			"depth_color", depth_color)


func _array_to_color(color_array: Array) -> Color:
	return Color(color_array[0] / 255, color_array[1] / 255, color_array[2] / 255)


func _process(delta):
	super._process(delta)
	
	for decal in $Decals.get_children():
		decal.update(position_manager.center_node.position)


func _on_wind_speed_changed(new_wind_speed):
	for chunk in chunks:
		chunk.get_node("Mesh").material_override.next_pass.set_shader_parameter("wind_speed", new_wind_speed)
