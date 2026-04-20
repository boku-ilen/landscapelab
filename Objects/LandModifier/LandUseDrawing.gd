extends Node3D

var feature: GeoFeature :
	set(new_feature):
		_apply_feature(new_feature)
	get(): return feature
	
func _apply_feature(geo_feature: GeoFeature):
	var quad: MeshInstance3D = $OverlayQuad
	#var feature_pos = geo_feature.get_vector3()
	#position = Vector3(feature_pos.x, 0, feature_pos.z)
	var string_attributes = geo_feature.get_attributes()
	var lid = int(string_attributes["lid"])
	var width = int(string_attributes["width"])
	var height = int(string_attributes["height"])
	var bin_data = geo_feature.get_binary_attribute("image")
	var img = ImageTexture.create_from_image(Image.create_from_data(width, height, false, Image.FORMAT_R8, bin_data))
	var mat: ShaderMaterial = quad.get_active_material(0)
	mat = mat.duplicate()
	mat.set_shader_parameter("color", Color8(
		lid % 255,
		floor(lid / 255),
		0
	))
	mat.set_shader_parameter("raster", img)
	quad.material_override = mat
	var pixel_scale = float(string_attributes["meters_per_pixel"])
	
	print(Vector3(width, height, 0) * pixel_scale)
	quad.scale = Vector3(width, height, 1.0) * pixel_scale;
