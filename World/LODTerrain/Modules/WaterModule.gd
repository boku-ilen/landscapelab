tool
extends Module

onready var water_mesh = get_node("MeshInstance")

var splat_result
var splatmap
var dhm

var WATER_SPLAT_ID = Settings.get_setting("water", "water-splat-id")


func get_textures(tile):
	var true_pos = tile.get_true_position()  # FIXME: gives me a nonexisting function in base 'Viewport'

	splat_result = ServerConnection.get_json("/%s/%d.0/%d.0/%d"\
		% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()])
		
	var dhm_response = tile.get_texture_result("raster")
	if dhm_response and dhm_response.has("dhm"):
		dhm = CachingImageTexture.get(dhm_response.get("dhm"), 0)


func set_splatmap():
	water_mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(water_mesh.material_override)
	
	water_mesh.material_override.set_shader_param("splatmap", splatmap)
	water_mesh.material_override.set_shader_param("water_id", WATER_SPLAT_ID)
	water_mesh.material_override.set_shader_param("heightmap", dhm)


func init(data=null):
	get_textures(tile)
	apply_textures()
	
	_done_loading()


func apply_textures():
	if not splat_result or not splat_result.has("path_to_splatmap"):
		return
		
	if splat_result["ids"].has(WATER_SPLAT_ID):
		splatmap = CachingImageTexture.get(splat_result.get("path_to_splatmap"), 0)
		
		set_splatmap()
