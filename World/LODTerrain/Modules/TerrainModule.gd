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
	var img = tile.get_texture_from_geodata("/home/retour/LandscapeLab/testdata/webm.tif")
	mesh.material_override.set_shader_param("heightmap", img)
	
	var ortho = tile.get_raster_from_pyramid("raster/bmaporthofoto30cm/", "jpg")
	mesh.material_override.set_shader_param("tex", ortho)
	
	return true
