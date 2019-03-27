tool
extends Module

#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#

onready var mesh = get_node("MeshInstance")

func _ready():
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	#ThreadPool.enqueue_task(ThreadPool.Task.new(self, "set_texture", []))
	set_texture([])
	
func set_texture(data):
	var zoom = tile.get_osm_zoom()
	
	# Orthophoto and heightmap
	var ortho = tile.get_texture_recursive("ortho", zoom, 0)
	var dhm = tile.get_texture_recursive("dhm", zoom, 0)
	
	mesh.material_override.set_shader_param("tex", ortho)
	mesh.material_override.set_shader_param("heightmap", dhm)
	
	if tile.lod > 2:
		var true_pos = tile.get_true_position()

		var splat_result = ServerConnection.get_json("/%s/%d.0/%d.0/%d"\
			% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()])
			
		if not splat_result or splat_result.has("Error") or not splat_result.has("ids"):
			done_loading()
			return
		
		var result = ServerConnection.get_json("/vegetation/%d/1" % [splat_result.ids[0]])
		
		if not result or result.has("Error"):
			done_loading()
			return
			
		if result.has("albedo_path") and splat_result.has("path_to_splatmap"):
			var albedo = CachingImageTexture.get(result.get("albedo_path"))
			var splat = CachingImageTexture.get(splat_result.get("path_to_splatmap"))
			
			mesh.material_override.set_shader_param("splat", splat)
			mesh.material_override.set_shader_param("vegetation_tex1", albedo)
			mesh.material_override.set_shader_param("vegetation_id1", splat_result.ids[0])
			
	done_loading()
