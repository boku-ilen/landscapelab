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
	var response
	var max_iterations = 10
	var iteration = 0
	
	var true_pos = tile.get_true_position()
	
	var img = Geodot.save_tile_from_heightmap(
		"/home/retour/LandscapeLab/testdata/webm.tif",
		"/home/retour/LandscapeLab/testdata/tile.tif",
		-true_pos[0] - tile.size / 2,
		true_pos[2] + tile.size / 2,
		tile.size,
		256
	)
	
	mesh.material_override.set_shader_param("heightmap", img)
	
	var ortho = tile.get_raster_from_pyramid("raster/bmaporthofoto30cm/", "jpg")
	
	mesh.material_override.set_shader_param("tex", ortho)
	
	return true
