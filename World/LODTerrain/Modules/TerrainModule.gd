tool
extends Module

#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#

var height_tex = preload("res://Materials/heightmap.png") # TODO: Testing only! In the future, this texture will be fetched from the server.

onready var mesh = get_node("MeshInstance")

func _ready():
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "set_texture", []))
	
func set_texture(data):
	var zoom = tile.get_osm_zoom()
	
	get_orthophoto_recursive(zoom, 0)
	
	# TODO: Also request this!
	mesh.material_override.set_shader_param("heightmap", height_tex)
	
func get_orthophoto_recursive(zoom, steps):
	var true_pos = tile.get_true_position()
	
	var result = ServerConnection.getJson("/raster/%d.0/%d.0/%d.json"\
		% [-true_pos[0], true_pos[2], zoom])
		
	if result.has("Error"):
		# TODO: How to react to this? Currently no done_loading() is sent, so if there ever is an error, the client is
		# stuck here
		return
	
	# If there is no orthophoto at this zoom level, go back recursively
	if result.get("ortho") == "None":
		get_orthophoto_recursive(zoom - 1, steps + 1)
		return
		
	var ortho = CachingImageTexture.get(result.get("ortho"))
	
	# If we went back, get the cropped image
	if steps > 0:
		var size = 1.0 / pow(2, steps)
		var origin = tile.get_offset_from_parents(steps)
		
		ortho = CachingImageTexture.get_cropped(result.get("ortho"), origin, Vector2(size, size))
	
	mesh.material_override.set_shader_param("tex", ortho)
	done_loading()
	
# Returns the height on the tile at a certain position (the y coordinate of the passed vector is ignored)
# TODO: Maybe change into get_position_on_ground and return whole position for ease of use?
func get_height_at_position(var pos):
	var img = height_tex.get_data()
	img.lock()
	var pos_scaled = (Vector2(pos.x, pos.z) - Vector2(translation.x, translation.z) + Vector2(tile.size / 2, tile.size / 2)) / tile.size
	var pix_pos = pos_scaled * img.get_size()
	
	# Clamp to max values
	pix_pos.x = clamp(pix_pos.x, 0, img.get_size().x - 1)
	pix_pos.y = clamp(pix_pos.y, 0, img.get_size().y - 1)
	
	var height = img.get_pixel(pix_pos.x, pix_pos.y).g * 500 # TODO: Centralize height range and use here
	img.unlock()	

	return height