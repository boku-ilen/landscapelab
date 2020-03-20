tool
extends Module


#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#


func init(data=null):
	RenderStyle.connect("change_style", self, "update_render_style")
	
	var mesh = get_node("MeshInstance")
	
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	if not get_textures(tile, mesh):
		logger.error("get_textures failed!")
	
	update_render_style(RenderStyle.current_style)
	
	_done_loading()


func update_render_style(new_style):
	var mesh = get_node("MeshInstance")
	
	if new_style.name == "Realistic":
		mesh.material_override.set_shader_param("clay_rendering", false)
	elif new_style.name == "Abstract":
		mesh.material_override.set_shader_param("clay_rendering", true)


func get_textures(tile, mesh) -> bool:
	var dhm = tile.get_texture("heightmap")
	mesh.material_override.set_shader_param("heightmap", dhm)
	
	var ortho = tile.get_texture("orthophoto")
	mesh.material_override.set_shader_param("tex", ortho)
	
	return true
