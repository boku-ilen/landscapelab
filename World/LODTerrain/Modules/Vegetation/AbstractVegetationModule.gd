extends Module

#
# This module can be used for any vegetation. It efficiently renders this using a particle shader.
# The area can be filled with multiple different plants using a distribution image.
#

export var my_vegetation_layer = 4
export(Mesh) var plant_mesh_scene  # The mesh that plants are rendered on - must be scaled to 1m!
export(float) var max_plant_size  # The maximal plant size which is used as the size of the particle mesh
# TODO: The max_plant_size must be kept in sync with the server - it would be good to automatically fetch it
#  instead of having to set it manually! (Requires a new server request)
export(bool) var cast_shadow = false

var particles_scene = preload("res://World/LODTerrain/Modules/Util/HeightmapParticles.tscn")
var LODS = Settings.get_setting("herbage", "density-at-lod")
var density_modifiers = Settings.get_setting("herbage", "density-modifiers-for-layers")
var num_layers = Settings.get_setting("herbage", "max-vegetations-per-tile")

var result
var heightmap
var splatmap

# Holds image data for all phytocoenosis which will be loaded
var phyto_data = {}


func init(tile):
	.init(tile)
	
	self.tile = tile
	
	for i in range(0, num_layers):
		var instance = particles_scene.instance()
		instance.name = String(i)
		instance.set_mesh(plant_mesh_scene)
		instance.cast_shadow = cast_shadow
		add_child(instance)
	
	get_splat_data()
	
	_done_loading()
	_ready_to_be_displayed()


# Fetches all required data from the server
func get_splat_data():
	var true_pos = tile.get_true_position()
	var url = "/%s/%d.0/%d.0/%d"\
		% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()]

	# Vegetation result for this tile
	result = ServerConnection.get_json(url)
		
	# Load splatmap
	if result and result.has("path_to_splatmap"):
		splatmap = CachingImageTexture.get(result.get("path_to_splatmap"), 0)
		
	# Get heightmap
	var dhm_response = tile.get_texture_result("raster")
	if dhm_response and dhm_response.has("dhm"):
		# We need to use get_new since the vegetation uses different flags
		# than the default! (set in set_parameters)
		heightmap = CachingImageTexture.get(dhm_response.get("dhm"), 0)

	if result and result.has("ids"):
		# Iterate over all phytocoenosis IDs on this tile (but don't exceed num_layers)
		var valid_vegetations = 0
		
		for current_index in range(0, result.get("ids").size()):
			if valid_vegetations > num_layers: break
			
			# Data for the phytocoenosis with this ID
			var phyto_c_url = "/vegetation/%d/%d" % [result.get("ids")[current_index], my_vegetation_layer]
			var this_result = ServerConnection.get_json(phyto_c_url)
			
			# Load all images (distribution, spritesheet) and corresponding data
			# We do this here because doing it in the main thread causes big stutters
			if this_result:
				var dist = this_result.get("path_to_distribution")
				var sprite = this_result.get("path_to_spritesheet")
				var dist_ppm = this_result.get("distribution_pixels_per_meter")
				var sprite_num = this_result.get("number_of_sprites")
				
				# If all those variables are valid, we can insert the images/data into phyto_data
				if dist and sprite and dist_ppm and sprite_num:
					phyto_data[result.get("ids")[current_index]] = VegetationData.new(
						CachingImageTexture.get(dist, 0),
						CachingImageTexture.get(sprite),
						dist_ppm,
						sprite_num)
						
					valid_vegetations += 1
			else:
				logger.warning("Vegetation result with url %s was null - is the phytocoenosis not defined in the server?" % [phyto_c_url])
		
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
			if steps >= num_layers:
				break
			
			# Initialize the particle emitter
			var nd = get_node(String(node))
			var mod = density_modifiers[String(my_vegetation_layer)]
			nd.set_rows(tile.size * LODS[String(tile.lod)] * mod)
			nd.set_spacing(1 / (LODS[String(tile.lod)] * mod))
			
			if node > num_layers - 1: break
			set_parameters([nd, id])
			
			node += 1
			steps += 1


# Sets all shader parameters for both the particle shader and the texture shader of a HeightmapParticles instance
func set_parameters(data):
	if not heightmap:
		logger.error("Vegetation module did not receive a valid heightmap!")
		return
	
	if not phyto_data.has(data[1]):
		logger.debug("Phytocoenosis with ID %d has incomplete plant data - not an issue if it's intended to have no plants" % [data[1]])
		return
	
	var distribution = phyto_data[data[1]].distribution
	var spritesheet = phyto_data[data[1]].spritesheet
	var distribution_pixels_per_meter = phyto_data[data[1]].distribution_pixels_per_meter
	var sprite_count = phyto_data[data[1]].number_of_sprites
	
	if sprite_count == 0: return
	
	# Values for the material of the particles themselves
	data[0].material_override.set_shader_param("pos", translation)
	data[0].material_override.set_shader_param("spritesheet", spritesheet)
	data[0].material_override.set_shader_param("distribution", distribution)
	data[0].material_override.set_shader_param("sprite_count", sprite_count)
	data[0].material_override.set_shader_param("distribution_pixels_per_meter", distribution_pixels_per_meter)
	data[0].material_override.set_shader_param("scale", max_plant_size)
	
	# Values for the material which places the particles
	data[0].process_material.set_shader_param("tile_pos", translation)
	data[0].process_material.set_shader_param("splatmap", splatmap)
	data[0].process_material.set_shader_param("heightmap", heightmap)
	data[0].process_material.set_shader_param("scale", max_plant_size)
	data[0].process_material.set_shader_param("id", data[1])
	
	tile.set_heightmap_params_for_obj(data[0].process_material)
	tile.set_heightmap_params_for_obj(data[0].material_override)
	
	data[0].emit()


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
