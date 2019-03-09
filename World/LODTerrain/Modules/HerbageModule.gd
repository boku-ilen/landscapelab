extends Module

#
# This module can be used for any small vegetation such as grass, flowers and herbs. It efficiently renders this using a
# particle shader.
# The area can be filled with multiple different plants using a distribution image.
#

var grass_scene = preload("res://World/LODTerrain/Modules/Util/Grass.tscn")
var LODS = Settings.get_setting("herbage", "rows-at-lod")

signal got_splat_data

func _ready():
	# TODO: Doing this in a function that has anything to do with threads causes crashes...
	var instance = grass_scene.instance()
	instance.name = "Herbage"
	add_child(instance)
	
	# First, get the splatmap
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_splat_data", []))
	
	connect("got_splat_data", self, "construct_vegetation")
	
func get_splat_data(d):
	var result = ServerConnection.getJson("/vegetation/1.0/1.0")
	
	emit_signal("got_splat_data", result.get("path_to_splatmap"), result.get("ids"))
	
func construct_vegetation(splat_path, splat_ids):
	# For each splat_id, instance a grass_scene - unfortunately, instancing here causes crashes, so we will have to get
	# this fixed or find a different solution
	
	if LODS.has(String(tile.lod)):
		var grass = get_node("Herbage")
		
		grass.set_rows(LODS[String(tile.lod)])
		grass.set_spacing(tile.size / LODS[String(tile.lod)])
		
		var id = 1 # TODO: Replace with splat_id in the for loop mentioned above once it's working
		
		#ThreadPool.enqueue_task(ThreadPool.Task.new(self, "set_parameters", [grass, splat_path, id]))
		# Big crash improvement:
		set_parameters([grass, splat_path, id])
		
func set_parameters(data):
	var result = ServerConnection.getJson("/vegetation/1/1")
	
	if result.has("Error"):
		logger.error("Could not get vegetation!");
		return
	
	var distribution = CachingImageTexture.get(result.get("path_to_distribution"))
	var spritesheet = CachingImageTexture.get(result.get("path_to_spritesheet"))
	var splatmap = CachingImageTexture.get(data[1])
	var heightmap = tile.get_texture_recursive("dhm", tile.get_osm_zoom(), 0)
	
	var sprite_count = result.get("number_of_sprites")
	
	data[0].material_override.set_shader_param("pos", translation)
	data[0].material_override.set_shader_param("spritesheet", spritesheet)
	data[0].material_override.set_shader_param("distribution", distribution)
	data[0].material_override.set_shader_param("sprite_count", sprite_count)
	
	data[0].process_material.set_shader_param("tile_pos", translation)
	data[0].process_material.set_shader_param("splatmap", splatmap)
	data[0].process_material.set_shader_param("heightmap", heightmap)
	data[0].process_material.set_shader_param("id", data[2])
	
	tile.set_heightmap_params_for_obj(data[0].process_material)
	tile.set_heightmap_params_for_obj(data[0].material_override)
	
	done_loading()