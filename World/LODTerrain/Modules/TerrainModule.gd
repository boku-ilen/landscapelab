tool
extends Module

#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#

var detail_pass = preload("res://Materials/HeightmapDetailTexture.tres")

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
	
	var result = ServerConnection.getJson("/vegetation/4/1")
	var splat_result = ServerConnection.getJson("/vegetation/1.0/1.0")
	
	if result.has("Error") or splat_result.has("Error"):
		logger.error("Could not get vegetation!");
		return
		
	if result.has("albedo_path") and splat_result.has("path_to_splatmap"):
		var albedo = CachingImageTexture.get(result.get("albedo_path"))
		var splat = CachingImageTexture.get(splat_result.get("path_to_splatmap"))
		
		mesh.material_override.set_shader_param("splat", splat)
		mesh.material_override.set_shader_param("vegetation_tex1", albedo)
	
	done_loading()
