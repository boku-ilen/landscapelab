extends "res://World/LODTerrain/Modules/TerrainModule.gd"

var splat_result
var splatmap

var vegetations = []
var albedos = []
var normals = []

var vegetation_max = 4

var WATER_SPLAT_ID = Settings.get_setting("water", "water-splat-id")
var DETAIL_START_DIST = Settings.get_setting("herbage", "detail-texture-start-distance")


func get_splat_data():
	var true_pos = tile.get_true_position()

	splat_result = ServerConnection.get_json("/%s/%d.0/%d.0/%d"\
		% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()])

	if not splat_result or not splat_result.has("ids"):
		make_ready()
		return

	splatmap = CachingImageTexture.get(splat_result.get("path_to_splatmap"))
	
	var added_vegetations = 0
	# Add as many vegetations as available on server / possible on client
	for i in range(0, splat_result.ids.size()):
		if added_vegetations >= vegetation_max:
			break
		
		# We use the layer 1 here, but the layer doesn't matter - the detail textures are the
		# same on all layers (since all layers are on the same ground)
		var result = ServerConnection.get_json("/vegetation/%d/1" % [splat_result.ids[i]])
		
		if result:
			vegetations.append(result)
			albedos.append(CachingImageTexture.get(result.get("albedo_path")))
			normals.append(CachingImageTexture.get(result.get("normal_path")))
			
			added_vegetations += 1


func get_textures(data):
	get_ortho_dhm()
	get_splat_data()

	make_ready()


func _on_ready():
	._on_ready()
	
	if splat_result and splat_result.has("path_to_splatmap"):
		var current_index = 0
		
		mesh.material_override.set_shader_param("water_splat_id", WATER_SPLAT_ID)
		mesh.material_override.set_shader_param("splat", splatmap)
		mesh.material_override.set_shader_param("detail_start_dist", DETAIL_START_DIST)
		
		for result in vegetations:
			if result and result.has("albedo_path"):
				var albedo = albedos[current_index]

				mesh.material_override.set_shader_param("vegetation_tex%d" % [current_index + 1], albedo)
				mesh.material_override.set_shader_param("vegetation_id%d" % [current_index + 1], splat_result.ids[current_index])
				
				if result.has("normal_path"):
					var normal = normals[current_index]
					mesh.material_override.set_shader_param("vegetation_normal%d" % [current_index + 1], normal)
				
			current_index += 1
