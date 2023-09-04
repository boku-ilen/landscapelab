@tool
extends Resource
class_name WallTextureBundle

@export var albedo_texture: Texture
@export var normal_texture: Texture

@export var roughness_texture: Texture : 
	set(texture):
		roughness_texture = texture
		_on_bundled_texture_changed(roughness_texture, metallic_texture, emission_texture)
@export var metallic_texture: Texture: 
	set(texture):
		metallic_texture = texture
		_on_bundled_texture_changed(roughness_texture, metallic_texture, emission_texture)
@export var emission_texture: Texture: 
	set(texture):
		emission_texture = texture
		window_shading = true
		_on_bundled_texture_changed(roughness_texture, metallic_texture, emission_texture)

var window_shading := false

var bundled_texture


func _on_bundled_texture_changed(roughness: Texture, metallic: Texture, emission: Texture):
	# If no textures are set there is no sense in bundling
	if roughness == null and metallic == null and emission == null: return
	
	# Obtain raw data
	var roughness_data = _get_texture_channel_data(roughness)
	var metallic_data = _get_texture_channel_data(metallic)
	var emission_data = _get_texture_channel_data(emission)
	
	# Obtain the height from at least one of the set textures
	var height = roughness.get_image().get_height() if roughness != null \
			else (metallic.get_image().get_height() if metallic != null \
			else emission.get_image().get_height())
	var width = roughness.get_image().get_width() if roughness != null \
			else (metallic.get_image().get_width() if metallic != null \
			else emission.get_image().get_width())
	
	# The obtained data is an empty array in case of null-texture; fill with 0s
	_fill_empty(roughness_data, metallic_data, emission_data, height * width)
	
	# Check for same size
	var OK = roughness_data.size() == metallic_data.size() \
			and roughness_data.size() == emission_data.size()
	if not OK:
		push_error("Textures are not the same size!")
		return
	
	# Bundle raw array
	var bundled = _bundle( 
		roughness_data, 
		metallic_data, 
		emission_data)
	
	# Store at other textures place
	var path = roughness.resource_path if roughness != null \
			else (metallic.resource_path if metallic != null \
			else emission.resource_path)
	path = path.substr(0, path.rfind("/"))
	
	# Save image to disk and store the resulting texture
	var bundled_image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, bundled)
	bundled_image.generate_mipmaps()
	bundled_image.save_jpg(path + "/roughness_metallic_emission_bundled.jpg", 1.0)
	
	bundled_texture = ImageTexture.create_from_image(bundled_image)


func _get_texture_channel_data(texture: Texture) -> Array:
	if texture == null: return []
	
	var image = texture.get_image()
	# Steps necessary to prevent errors
	image.decompress()
	image.clear_mipmaps()
	image.convert(Image.FORMAT_R8)
	
	return image.get_data()


func _fill_empty(roughness_data, metallic_data, emission_data, size):
	if roughness_data.is_empty():
		roughness_data.resize(size)
		roughness_data.fill(0)
	
	if metallic_data.is_empty():
		metallic_data.resize(size)
		metallic_data.fill(0)
	
	if emission_data.is_empty():
		emission_data.resize(size)
		emission_data.fill(0)


func _bundle(roughness_data, metallic_data, emission_data):
	var bundle = func(arr1: Array, arr2: Array, arr3: Array):
		var new_arr = []
		new_arr.resize(arr1.size() + arr2.size() + arr3.size())
		new_arr.fill(0)
		
		for i in range(arr1.size()):
			new_arr[i * 3] = arr1[i]
			new_arr[i * 3 + 1] = arr2[i]
			new_arr[i * 3 + 2] = arr3[i]
			
		return new_arr
	
	var bundled = bundle.call(roughness_data, metallic_data, emission_data)
	
	return bundled
