@tool
extends Resource
class_name TextureBundleRME

# Editor tool to create bundled textures.
# Should only be used in the editor, as new textures are not saved while running the game.
# This is to prevent large loading times caused by all textures being created and saved on every startup.


@export var texture_scale := Vector2(1, 1)
@export var albedo_texture: Texture
@export var normal_texture: Texture

@export var roughness_texture: Texture : 
	set(texture):
		roughness_texture = texture
		
		if Engine.is_editor_hint():
			_on_bundled_texture_changed(roughness_texture, metallic_texture, emission_texture, albedo_texture)
@export var metallic_texture: Texture: 
	set(texture):
		metallic_texture = texture
		
		if Engine.is_editor_hint():
			_on_bundled_texture_changed(roughness_texture, metallic_texture, emission_texture, albedo_texture)
@export var emission_texture: Texture: 
	set(texture):
		emission_texture = texture
		window_shading = true
		
		if Engine.is_editor_hint():
			_on_bundled_texture_changed(roughness_texture, metallic_texture, emission_texture, albedo_texture)

var window_shading := false

var bundled_texture


func _on_bundled_texture_changed(roughness: Texture, metallic: Texture, 
								emission: Texture, albedo: Texture2D = null):
	# If no textures are set there is no sense in bundling
	if roughness == null and metallic == null and emission == null: 
		bundled_texture = null
		return
	
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
	
	# Try to obtain the alpha channel from the albedo
	var alpha_data = []
	if albedo != null and albedo.get_image().detect_alpha() != Image.AlphaMode.ALPHA_NONE:
		var albedo_image = albedo.get_image().duplicate(true)
		albedo_image.clear_mipmaps()
		albedo_image.decompress()
		var albedo_data = albedo_image.get_data()
		var count = 0
		for num in albedo_data:
			if count % 4 == 3:
				alpha_data.append(num)
			count += 1
	
	# Check for same size
	var OK = roughness_data.size() == metallic_data.size() \
			and roughness_data.size() == emission_data.size()
	if not OK:
		push_error("Textures are not the same size!")
		return
	
	# Alpha has to be either unset or same size
	OK = alpha_data.is_empty() or alpha_data.size() == roughness_data.size()
	if not OK:
		push_error("Alpha channel size is not the same as roughness/metallic/emission!")
		return
	
	# Bundle raw array
	var bundled = _bundle( 
		roughness_data, 
		metallic_data, 
		emission_data,
		alpha_data)
	
	# Store at other textures place
	var path = roughness.resource_path if roughness != null \
			else (metallic.resource_path if metallic != null \
			else emission.resource_path)
	path = path.substr(0, path.rfind("/"))
	
	# Save image to disk and store the resulting texture
	var bundled_image
	if not alpha_data.is_empty():
		bundled_image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, bundled)
	else:
		bundled_image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, bundled)
	
	bundled_image.generate_mipmaps()
	bundled_image.save_png(path + "/roughness_metallic_emission_bundled.png")
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


func _bundle(roughness_data, metallic_data, emission_data, alpha_data: Array = []):
	var bundle = func(arr1: Array, arr2: Array, arr3: Array, arr4: Array):
		var new_arr = []
		var array_size = arr1.size() + arr2.size() + arr3.size()
		# Include alpha channel
		array_size += arr4.size() if not arr4.is_empty() else 0
		new_arr.resize(array_size)
		new_arr.fill(0)
		
		var step = 3 + (1 if not arr4.is_empty() else 0)
		for i in range(arr1.size()):
			new_arr[i * step] = arr1[i]
			new_arr[i * step + 1] = arr2[i]
			new_arr[i * step + 2] = arr3[i]
			if not arr4.is_empty():
				new_arr[i * step + 3] = arr4[i]
			
		return new_arr
	
	var bundled = bundle.call(roughness_data, metallic_data, emission_data, alpha_data)
	
	return bundled
