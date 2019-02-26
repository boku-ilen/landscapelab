tool
extends Module

#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#

onready var mesh = get_node("MeshInstance")

func _ready():
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "set_texture", []))
	
func set_texture(data):
	var zoom = tile.get_osm_zoom()
	
	# Orthophoto and heightmap
	var ortho = tile.get_texture_recursive("ortho", zoom, 0)
	var dhm = tile.get_texture_recursive("dhm", zoom, 0)
	
	mesh.material_override.set_shader_param("tex", ortho)
	mesh.material_override.set_shader_param("heightmap", dhm)
	
	done_loading()
