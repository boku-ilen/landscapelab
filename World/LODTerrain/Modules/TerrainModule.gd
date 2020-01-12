tool
extends Module


#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#


func init(tile):
	.init(tile)
	
	var mesh = get_node("MeshInstance")
	
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	if get_textures(tile, mesh):
		_ready_to_be_displayed()
	
	_done_loading()


func get_textures(tile, mesh) -> bool:
	var response = tile.get_texture_result("raster")
	
	if response:
		var ortho
		var dhm
		
		if response.has("ortho"):
			ortho = CachingImageTexture.get(response.get("ortho"))
		if response.has("dhm"):
			dhm = CachingImageTexture.get(response.get("dhm"), 0)
		
		if ortho and dhm:
			# Don't let the subdivision get higher than the texture resolution, steep walls otherwise
			if dhm.get_width() < tile.subdiv:
				tile.subdiv = dhm.get_width()
	
			mesh.material_override.set_shader_param("tex", ortho)
			mesh.material_override.set_shader_param("heightmap", dhm)
			
			# Display only if both textures are here and valid
			return true
	
	return false
