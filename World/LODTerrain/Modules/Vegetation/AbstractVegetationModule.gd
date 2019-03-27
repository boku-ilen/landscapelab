extends Module

#
# This module can be used for any vegetation. It efficiently renders this using a particle shader.
# The area can be filled with multiple different plants using a distribution image.
#

export var num_layers = 1
export var my_vegetation_layer = 4
export(Mesh) var particle_mesh_scene

var particles_scene = preload("res://World/LODTerrain/Modules/Util/HeightmapParticles.tscn")
var LODS = Settings.get_setting("herbage", "rows-at-lod")

func _ready():
	# TODO: Doing this in a function that has anything to do with threads causes crashes...
	# This is we we instance a predefined amount at the start.
	for i in range(0, num_layers):
		var instance = particles_scene.instance()
		instance.name = String(i)
		instance.set_mesh(particle_mesh_scene)
		add_child(instance)
	
	# First, get the splatmap
	#ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_splat_data", []))
	get_splat_data([])
	
func get_splat_data(d):
	var true_pos = tile.get_true_position()
	
	var result = ServerConnection.get_json("/%s/%d.0/%d.0/%d"\
		% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()])

	construct_vegetation(result.get("path_to_splatmap"), result.get("ids"))
	
func construct_vegetation(splat_path, splat_ids):
	# For each splat_id, instance a particles_scene - unfortunately, instancing here causes crashes, so we will have to get
	# this fixed or find a different solution
	
	if LODS.has(String(tile.lod)):
		var node = 0
		var steps = 0
		
		for id in splat_ids:
			if steps >= num_layers:
				break
			
			var nd = get_node(String(node))
		
			nd.set_rows(LODS[String(tile.lod)])
			nd.set_spacing(tile.size / LODS[String(tile.lod)])
			
			if node > num_layers - 1: break
			set_parameters([nd, splat_path, id, node])
			node += 1
			# Big crash improvement:
			#set_parameters([grass, splat_path, id])
			
			steps += 1
			
	done_loading()
		
func set_parameters(data):
	var result = ServerConnection.get_json("/vegetation/%d/%d" % [data[2], my_vegetation_layer])
	
	if not result or result.has("Error") or not result.get("path_to_spritesheet"):
		logger.error("Could not get vegetation!");
		return
	
	var distribution = CachingImageTexture.get(result.get("path_to_distribution"))
	var spritesheet = CachingImageTexture.get(result.get("path_to_spritesheet"))
	var distribution_pixels_per_meter = result.get("distribution_pixels_per_meter")
	var splatmap = CachingImageTexture.get(data[1])
	var heightmap = tile.get_texture_recursive("dhm", tile.get_osm_zoom(), 0)
	
	heightmap.flags = 4  # Enable filtering for smooth slopes
	
	var sprite_count = result.get("number_of_sprites")
	
	data[0].material_override.set_shader_param("pos", translation)
	data[0].material_override.set_shader_param("spritesheet", spritesheet)
	data[0].material_override.set_shader_param("distribution", distribution)
	data[0].material_override.set_shader_param("sprite_count", sprite_count)
	data[0].material_override.set_shader_param("distribution_pixels_per_meter", distribution_pixels_per_meter)
	
	data[0].process_material.set_shader_param("tile_pos", translation)
	data[0].process_material.set_shader_param("splatmap", splatmap)
	data[0].process_material.set_shader_param("heightmap", heightmap)
	data[0].process_material.set_shader_param("id", data[2])
	
	tile.set_heightmap_params_for_obj(data[0].process_material)
	tile.set_heightmap_params_for_obj(data[0].material_override)