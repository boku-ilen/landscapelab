extends "res://World/LODTerrain/Modules/TerrainModule.gd"

#
# This module extends the TerrainModule to add rough detail to the orthophoto
# based on land-use data.
#


func get_textures(tile, mesh):
	var super_textures = .get_textures(tile, mesh)
	var new_textures = get_splatmap(tile, mesh)
	
	return super_textures and new_textures


func get_splatmap(tile, mesh):
	var splatmap = tile.get_texture("sentinel-invekos-bytes", "tif", 6)
	
	mesh.material_override.set_shader_param("splat", splatmap)
	mesh.material_override.set_shader_param("fake_forests", true)
	mesh.material_override.set_shader_param("forest_height", 20.0)
	
	return true
