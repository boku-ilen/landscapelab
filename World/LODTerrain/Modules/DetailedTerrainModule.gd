extends "res://World/LODTerrain/Modules/TerrainModule.gd"

var splat_result
var result

func get_splat_data():
	var true_pos = tile.get_true_position()

	splat_result = ServerConnection.get_json("/%s/%d.0/%d.0/%d"\
		% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()])

	if not splat_result or not splat_result.has("ids"):
		make_ready()
		return

	result = ServerConnection.get_json("/vegetation/%d/1" % [splat_result.ids[0]])

func get_textures(data):
	get_ortho_dhm()
	get_splat_data()

	make_ready()
	
func _on_ready():
	._on_ready()
	
	if splat_result and result:
		if result.has("albedo_path") and splat_result.has("path_to_splatmap"):
			var albedo = CachingImageTexture.get(result.get("albedo_path"))
			var splat = CachingImageTexture.get(splat_result.get("path_to_splatmap"))
	
			mesh.material_override.set_shader_param("splat", splat)
			mesh.material_override.set_shader_param("vegetation_tex1", albedo)
			mesh.material_override.set_shader_param("vegetation_id1", splat_result.ids[0])