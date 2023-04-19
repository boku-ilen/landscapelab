extends Object
class_name StructuredTexture

#
# Loads images and textures from a folder with a pre-defined structure.
# Useful for e.g. loading 'albedo.jpg' and 'roughness.jpg' from a selected folder.
#


const DEFAULT_ENDING = ".jpg"

const ALBEDO_NAME = "albedo"
const NORMAL_NAME = "normal"
const ROUGHNESS_NAME = "roughness"
const AO_NAME = "ambient"


# Get a material which uses all textures with the defined texture names (see above) that exist in
# the given directory.
static func get_material(base_path: String, ending: String = DEFAULT_ENDING) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	
	if texture_exists(base_path, ALBEDO_NAME, ending):
		material.albedo_texture = get_texture(base_path, ALBEDO_NAME, ending)
	if texture_exists(base_path, NORMAL_NAME, ending):
		material.normal_enabled = true
		material.normal_texture = get_texture(base_path, NORMAL_NAME, ending)
	if texture_exists(base_path, ROUGHNESS_NAME, ending):
		material.roughness_texture = get_texture(base_path, ROUGHNESS_NAME, ending)
	if texture_exists(base_path, AO_NAME, ending):
		material.ao_enabled = true
		material.ao_texture = get_texture(base_path, AO_NAME, ending)
	
	return material


static func texture_exists(base_path: String, name: String, ending: String = DEFAULT_ENDING) -> bool:
	return FileAccess.file_exists(_get_full_path(base_path, name, ending))


static func get_texture(base_path: String, name: String, ending: String = DEFAULT_ENDING) -> ImageTexture:
	var image = get_image(base_path, name, ending)
	
	return ImageTexture.create_from_image(image) #,flags


static func _get_full_path(base_path: String, name: String, ending: String) -> String:
	return base_path.path_join(name + ending)


static func get_image(base_path: String, name: String, ending: String = DEFAULT_ENDING) -> Image:
	var full_path = _get_full_path(base_path, name, ending)

	var img = load(full_path)
	
	if not img or img.is_empty():
		logger.error("Trying to load invalid texture at path %s!" % [full_path])
	
	return img
