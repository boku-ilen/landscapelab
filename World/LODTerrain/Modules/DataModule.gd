tool
extends Module


#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#


func init(data=null):
	var mesh = get_node("MeshInstance")
	
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	if not get_textures(tile, mesh, "avg_temperature", "avg_precipitation"):
		logger.error("get_textures failed!")
	
	_done_loading()


func get_textures(tile, mesh, texture: String, height: String) -> bool:
	var h = tile.get_geoimage(height)
	mesh.material_override.set_shader_param("height", h.get_image_texture())
	mesh.material_override.set_shader_param("normalmap", h.get_normalmap_texture_for_heightmap(0.1))
	mesh.material_override.set_shader_param("height_multiplicator", 15)
	
	
	var text = tile.get_texture(texture)
	mesh.material_override.set_shader_param("tex", text)
	mesh.material_override.set_shader_param("startcolor", Color.blue)
	mesh.material_override.set_shader_param("endcolor",  Color.red)
	
	return true
