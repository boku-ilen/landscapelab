tool
extends Module

var splatmap
var dhm

var WATER_SPLAT_ID = Settings.get_setting("water", "water-splat-id")


func get_textures(tile):
	splatmap = tile.get_texture("land-use", 6)
	dhm = tile.get_texture("heightmap")


func set_splatmap():
	var water_mesh = get_node("MeshInstance")
	
	water_mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(water_mesh.material_override)
	
	water_mesh.material_override.set_shader_param("splatmap", splatmap)
	water_mesh.material_override.set_shader_param("water_id", WATER_SPLAT_ID)
	water_mesh.material_override.set_shader_param("heightmap", dhm)


func init(data=null):
	get_textures(tile)
	
	# TODO: Only do this if there's (non-insignificant) water in the splatmap
	set_splatmap()
	
	_done_loading()
