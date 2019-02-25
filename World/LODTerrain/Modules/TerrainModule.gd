tool
extends Module

#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#

onready var mesh = get_node("MeshInstance")
var textures = {}

func _ready():
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "set_texture", []))
	
func set_texture(data):
	var zoom = tile.get_osm_zoom()
	
	# Orthophoto and heightmap
	get_texture_recursive("ortho", "tex", zoom, 0)
	get_texture_recursive("dhm", "heightmap", zoom, 0)
	
	done_loading()
	
func get_texture_recursive(tex_name, shader_param, zoom, steps):
	var true_pos = tile.get_true_position()
	
	var result = ServerConnection.getJson("/raster/%d.0/%d.0/%d.json"\
		% [-true_pos[0], true_pos[2], zoom])
		
	if result.has("Error"):
		# TODO: How to react to this? Currently no done_loading() is sent, so if there ever is an error, the client is
		# stuck here
		return
	
	# If there is no orthophoto at this zoom level, go back recursively
	if result.get(tex_name) == "None":
		get_texture_recursive(tex_name, shader_param, zoom - 1, steps + 1)
		return
		
	var tex = CachingImageTexture.get(result.get(tex_name))
	
	# If we went back, get the cropped image
	if steps > 0:
		var size = 1.0 / pow(2, steps)
		var origin = tile.get_offset_from_parents(steps)
		
		tex = CachingImageTexture.get_cropped(result.get(tex_name), origin, Vector2(size, size))
	
	textures[tex_name] = tex
	mesh.material_override.set_shader_param(shader_param, tex)
	
# Returns the height on the tile at a certain position (the y coordinate of the passed vector is ignored)
# TODO: Maybe change into get_position_on_ground and return whole position for ease of use?
func get_height_at_position(var pos):
	# TODO: Need to find a nice solution to make this work while keeping the module's modularity, this current solution
	# can make things break and get out of sync easily
	if not textures.has("dhm"):
		return 0
	
	var img = textures["dhm"].get_data()
	img.lock()
	var pos_scaled = (Vector2(pos.x, pos.z) - Vector2(translation.x, translation.z) + Vector2(tile.size / 2, tile.size / 2)) / tile.size
	var pix_pos = pos_scaled * img.get_size()
	
	# Clamp to max values
	pix_pos.x = clamp(pix_pos.x, 0, img.get_size().x - 1)
	pix_pos.y = clamp(pix_pos.y, 0, img.get_size().y - 1)
	
	var height = img.get_pixel(pix_pos.x, pix_pos.y).g * 500 # TODO: Centralize height range and use here
	img.unlock()	

	return height