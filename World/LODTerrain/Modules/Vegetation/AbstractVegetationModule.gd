extends Module

#
# This module can be used for any vegetation. It efficiently renders this using a particle shader.
# The area can be filled with multiple different plants using a distribution image.
#

export var num_layers = 1
export var my_vegetation_layer = 4
export(Mesh) var particle_mesh_scene

var particles_scene = preload("res://World/LODTerrain/Modules/Util/HeightmapParticles.tscn")
var LODS = Settings.get_setting("herbage", "density-at-lod")

var result
var heightmap
var splatmap

# Holds image data for all phytocoenosis which will be loaded
var phyto_data = {}


func _ready():
	for i in range(0, num_layers):
		var instance = particles_scene.instance()
		instance.name = String(i)
		instance.set_mesh(particle_mesh_scene)
		add_child(instance)
	
	# First, get the splatmap
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_splat_data", []))


# Fetches all required data from the server
func get_splat_data(d):
	var true_pos = tile.get_true_position()
	var url = "/%s/%d.0/%d.0/%d"\
		% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()]

	# Vegetation result for this tile
	result = ServerConnection.get_json(url)
		
	# Load splatmap
	if result and result.has("path_to_splatmap"):
		splatmap = CachingImageTexture.get(result.get("path_to_splatmap"))
		
	# Get heightmap
	var dhm_response = tile.get_texture_result("raster")
	if dhm_response and dhm_response.has("dhm"):
		# We need to use get_new since the vegetation uses different flags
		# than the default! (set in set_parameters)
		heightmap = CachingImageTexture.get_new(dhm_response.get("dhm"))

	if result and result.has("ids"):
		# Iterate over all phytocoenosis IDs on this tile (but don't exceed num_layers)
		for current_index in range(0, min(result.get("ids").size(), num_layers)):
			# Data for the phytocoenosis with this ID
			var pytho_c_url = "/vegetation/%d/%d" % [result.get("ids")[current_index], my_vegetation_layer]
			var this_result = ServerConnection.get_json(pytho_c_url)
			
			# Load all images (distribution, spritesheet) and corresponding data
			# We do this here because doing it in the main thread causes big stutters
			if CachingImageTexture and this_result:
				var dist = this_result.get("path_to_distribution")
				var sprite = this_result.get("path_to_spritesheet")
				var dist_ppm = this_result.get("distribution_pixels_per_meter")
				var sprite_num = this_result.get("number_of_sprites")
				
				# If all those variables are valid, we can insert the images/data into phyto_data
				if dist and sprite and dist_ppm and sprite_num:
					phyto_data[result.get("ids")[current_index]] = VegetationData.new(
						CachingImageTexture.get(dist),
						CachingImageTexture.get(sprite),
						dist_ppm,
						sprite_num)
				else:
					logger.warning("At least one of the returned values of %s was invalid!" % [pytho_c_url])
			else:
				logger.error("AbstractVegetationModule.gd:get_splat_data(): CachingImageTexture (%s) or server_result (%s) is null" % [CachingImageTexture, this_result])
		
	make_ready()


func _on_ready():
	if result:
		construct_vegetation(result.get("ids"))
	else:
		logger.warning("Vegetation module did not receive a response! Deleting particle scenes...")
		
		# Delete the particle emitters since they will not be needed
		for child in get_children():
			child.queue_free()


# Readies all required HeightmapParticles instances
func construct_vegetation(splat_ids):
	if LODS.has(String(tile.lod)):
		var node = 0
		var steps = 0
		
		for id in splat_ids:
			# TODO: We might want to check here whether we have all required data for the
			# phytocoenosis with this ID
			
			if steps >= num_layers:
				break
			
			# Initialize the particle emitter
			var nd = get_node(String(node))
			nd.set_rows(tile.size * LODS[String(tile.lod)])
			nd.set_spacing(1 / LODS[String(tile.lod)])
			
			if node > num_layers - 1: break
			set_parameters([nd, id])
			
			node += 1
			steps += 1


# Sets all shader parameters for both the particle shader and the texture shader of a HeightmapParticles instance
func set_parameters(data):
	if not heightmap or not phyto_data.has(data[1]):
		logger.warning("Vegetation module received a response, but the response contained invalid or incomplete data!");
		return
	
	var distribution = phyto_data[data[1]].distribution
	var spritesheet = phyto_data[data[1]].spritesheet
	var distribution_pixels_per_meter = phyto_data[data[1]].distribution_pixels_per_meter
	var sprite_count = phyto_data[data[1]].number_of_sprites
	
	heightmap.flags = 4  # Enable filtering for smooth slopes
	
	# Values for the material of the particles themselves
	data[0].material_override.set_shader_param("pos", translation)
	data[0].material_override.set_shader_param("spritesheet", spritesheet)
	data[0].material_override.set_shader_param("distribution", distribution)
	data[0].material_override.set_shader_param("sprite_count", sprite_count)
	data[0].material_override.set_shader_param("distribution_pixels_per_meter", distribution_pixels_per_meter)
	
	# Values for the material which places the particles
	data[0].process_material.set_shader_param("tile_pos", translation)
	data[0].process_material.set_shader_param("splatmap", splatmap)
	data[0].process_material.set_shader_param("heightmap", heightmap)
	data[0].process_material.set_shader_param("id", data[1])
	
	tile.set_heightmap_params_for_obj(data[0].process_material)
	tile.set_heightmap_params_for_obj(data[0].material_override)
	

# Basic data structure for the data of one phytocoenosis
class VegetationData:
	var distribution
	var spritesheet
	var distribution_pixels_per_meter
	var number_of_sprites
	
	func _init(dist, s, ppm, nns):
		distribution = dist
		spritesheet = s
		distribution_pixels_per_meter = ppm
		number_of_sprites = nns
