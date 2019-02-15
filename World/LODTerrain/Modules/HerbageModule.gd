extends Module

#
# This module can be used for any small vegetation such as grass, flowers and herbs. It efficiently renders this using a particle shader.
# The area can be filled with multiple different plants using a distribution image.
#

var grass_scene = preload("res://World/LODTerrain/Modules/Util/Grass.tscn")

var LODS = Settings.get_setting("herbage", "rows-at-lod")

func _ready():
	# Get required herbage for this scene + textures etc
	if LODS.has(String(tile.lod)):
		var instance = grass_scene.instance()
		instance.name = "Herbage"
		add_child(instance)
		
		var grass = get_node("Herbage")
		
		grass.set_rows(LODS[String(tile.lod)])
		grass.set_spacing(tile.size / LODS[String(tile.lod)])
		
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "set_parameters", [grass]))
		
func set_parameters(data):
	var result = ServerConnection.getJson("/vegetation/1/1")
	
	if result.has("Error"):
		logger.error("Could not get vegetation!");
		return
		
	var distribution_img = Image.new()
	distribution_img.load(result.get("path_to_distribution"))
	var distribution = ImageTexture.new()
	distribution.create_from_image(distribution_img, 8)
	
	var spritesheet_img = Image.new()
	spritesheet_img.load(result.get("path_to_spritesheet"))
	var spritesheet = ImageTexture.new()
	spritesheet.create_from_image(spritesheet_img, 8)
	
	var sprite_count = result.get("number_of_sprites")
	
	data[0].material_override.set_shader_param("pos", translation)
	data[0].material_override.set_shader_param("spritesheet", spritesheet)
	data[0].material_override.set_shader_param("distribution", distribution)
	data[0].material_override.set_shader_param("sprite_count", sprite_count)
	
	tile.set_heightmap_params_for_obj(data[0].process_material)
	tile.set_heightmap_params_for_obj(data[0].material_override)
