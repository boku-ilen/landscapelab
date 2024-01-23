extends Node
class_name TextureArrays


static func texture_arrays_from_wallres(wall_resources: Array):
	var albedo_images = []
	var normal_images = []
	var roughness_metallic_emission_images = []
	
	# Build texture-arrays of format: 
	# [type1_basement, type1_ground, type1_middle, type1_top, type2_basement, ...]
	for r in wall_resources:
		var res: PlainWallResource = r
		for bundle in [res.basement_texture, res.ground_texture, res.middle_texture, res.top_texture]:
			var images = formatted_images_from_textures(
				[bundle.albedo_texture, bundle.normal_texture, bundle.bundled_texture])
			
			albedo_images.append(images[0])
			normal_images.append(images[1])
			roughness_metallic_emission_images.append(images[2])
	
	var albedo_texture_array = texture2Darrays_from_images(albedo_images)
	var normal_texture_array = texture2Darrays_from_images(normal_images)
	var roughness_metallic_emission_texture_array = texture2Darrays_from_images(roughness_metallic_emission_images)
	
	return [albedo_texture_array, normal_texture_array, roughness_metallic_emission_texture_array]


static func formatted_images_from_textures(textures: Array[Texture], width := 1024, height := 1024):
	var images = []
	
	for texture in textures:
		# Ensure all images are the same size and same format and have mipmaps generated
		var new_image: Image = texture.get_image() \
			if  texture != null else Image.create(
				width, height, false, Image.FORMAT_RGBA8)
		new_image.decompress()
		new_image.flip_y()
		new_image.resize(width, height)
		new_image.convert(Image.FORMAT_RGBA8)
		if not new_image.has_mipmaps(): new_image.generate_mipmaps()
		images.append(new_image)
	
	return images 


static func texture2Darrays_from_images(images: Array):
	var texture_array = Texture2DArray.new()
	texture_array.create_from_images(images)
	
	return texture_array
