extends Module

#
# This module fetches the topomap for its tile, to be displayed on the minimap.
#

func init(tile):
	.init(tile)
	
	var mesh = get_node("MeshInstance")
	
	mesh.mesh = tile.create_tile_plane_mesh()
	
	get_textures(tile, mesh)
	
	# TODO: Only if get_textures was successful, or do we ignore this here?
	_ready_to_be_displayed()
	_done_loading()


func get_textures(tile, mesh) -> bool:
	var response = tile.get_texture_result("raster")
	
	if response:
		if response.has("map"):
			var topo = CachingImageTexture.get(response.get("map"))
			
			if topo:
				mesh.material_override.albedo_texture = topo
				
				return true
	
	return false
