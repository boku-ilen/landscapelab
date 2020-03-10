tool
extends Module


#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#


func init(data=null):
	var mesh = get_node("MeshInstance")
	
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	if not get_textures(tile, mesh):
		logger.error("get_textures failed!")
	
	_done_loading()


func get_textures(tile, mesh) -> bool:
	var dhm = tile.get_texture("webm", "tif")
	mesh.material_override.set_shader_param("heightmap", dhm)
	
	var ortho = tile.get_texture("webm", "tif") # TODO: tile.get_texture("bmaporthofoto30cm", "jpg")
	mesh.material_override.set_shader_param("tex", ortho)
	
	return true
