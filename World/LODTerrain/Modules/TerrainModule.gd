tool
extends Module

#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#

var grass_tex = preload("res://Resources/Textures/grass-ground.jpg") # TODO: Testing only! In the future, this texture will be fetched from the server.

onready var mesh = get_node("MeshInstance")

func _ready():
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "set_texture", []))
	
func set_texture(data):
	var zoom = tile.get_osm_zoom()
	
	get_orthophoto_recursive(zoom, 0)
	
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