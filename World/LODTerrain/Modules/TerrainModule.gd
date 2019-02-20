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
	var true_pos = tile.get_true_position()
	var zoom = tile.get_osm_zoom()
	
	var result = ServerConnection.getJson("/raster/%d.0/%d.0/%d.json"\
		% [-true_pos[0], true_pos[2], zoom])
		
	if result.has("Error"):
		# TODO: Use the previous orthophoto and split it like in WorldTile's split!
		logger.error("Could not get orthophoto!")
		done_loading()
		return
	
	var ortho = CachingImageTexture.get(result.get("ortho"))
	
	mesh.material_override.set_shader_param("tex", ortho)
	done_loading()