extends "res://World/LODTerrain/Modules/TerrainModule.gd"

var splat_result

var vegetations = []
var vegetation_max = 4

func get_splat_data():
	var true_pos = tile.get_true_position()

	splat_result = ServerConnection.get_json("/%s/%d.0/%d.0/%d"\
		% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()])

	if not splat_result or not splat_result.has("ids"):
		make_ready()
		return

	for i in range(0, min(splat_result.ids.size(), vegetation_max)):
		vegetations.append(ServerConnection.get_json("/vegetation/%d/1" % [splat_result.ids[i]]))

func get_textures(data):
	get_ortho_dhm()
	get_splat_data()

	make_ready()
	
func _on_ready():
	._on_ready()
	
	if splat_result and splat_result.has("path_to_splatmap"):
		var current_index = 0
		
		for result in vegetations:
			if result and result.has("albedo_path"):
				var albedo = CachingImageTexture.get(result.get("albedo_path"))
				var splat = CachingImageTexture.get(splat_result.get("path_to_splatmap"))
		
				mesh.material_override.set_shader_param("splat", splat)
				mesh.material_override.set_shader_param("vegetation_tex%d" % [current_index + 1], albedo)
				mesh.material_override.set_shader_param("vegetation_id%d" % [current_index + 1], splat_result.ids[current_index])
				
			current_index += 1