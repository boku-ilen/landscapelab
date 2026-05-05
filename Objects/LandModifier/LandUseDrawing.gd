extends Node3D


@export var lid_material: ShaderMaterial
@export var start_height := 5.0
@export var height_step := 0.02


var feature: GeoFeature :
	set(new_feature):
		feature = new_feature
		_apply_feature(new_feature)
	get(): return feature


func _apply_feature(geo_feature: GeoFeature):
	var quad: MeshInstance3D = $OverlayQuad
	
	var string_attributes = geo_feature.get_attributes()
	var lid = int(string_attributes["lid"])
	var width = int(string_attributes["width"])
	var height = int(string_attributes["height"])
	var bin_data = geo_feature.get_binary_attribute("image")
	
	var image = Image.create_from_data(width, height, false, Image.FORMAT_R8, bin_data)
	
	if not image:
		logger.error("Couldn't create image from binary field in feature with ID %s" [int(geo_feature.get_id())])
		visible = false
		return
	
	var texture = ImageTexture.create_from_image(image)
	
	# Duplicate the material to make changes to it not affect other instances
	var mat: ShaderMaterial = lid_material.duplicate()
	
	mat.set_shader_parameter("color", Color8(
		lid % 255,
		floor(lid / 255),
		0
	))
	mat.set_shader_parameter("raster", texture)
	
	quad.material_override = mat
	
	# We can use the scale directly because 1 unit corresponds to 1 meter with the projections we use
	var pixel_scale = float(string_attributes["meters_per_pixel"])
	quad.scale = Vector3(width * pixel_scale, height * pixel_scale, 1.0)
	# Apply the start height plus a small offset to make sure newer drawings are on top of older ones
	quad.position.y = start_height + height_step * float(geo_feature.get_id())
	
func set_height(v):
	$OverlayQuad.position.y = start_height + height_step * float(feature.get_id()) - global_position.y
