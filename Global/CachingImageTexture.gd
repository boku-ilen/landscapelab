extends Node

#
# This script allows ImageTextures to be loaded from any path in the filesystem, also outside the project directory.
# It caches every loaded image so that it doesn't load an image from the same path twice.
#

var _path_imagetexture_dict: Dictionary = {}
var _load_mutex = Mutex.new()
var _flags = 0
var _full_path_prefix = Settings.get_setting("filesystem", "local-resources-path")


# Returns the image at the given path as an ImageTexture.
# If the image has been loaded before, it is returned from the cache dictionary.
func get(path):
	_load_into_dict_if_needed(path)
		
	return _get_texture_from_dict(path)


# Returs a part of the ImageTexture at the given path. Origin and size are Vector2 with fields between 0 and 1.
# Example: Get the bottom left quarter of an image: Origin = (0, 0.5); Size = (0.5, 0.5)
func get_cropped(path, origin, size):
	_load_into_dict_if_needed(path)
	
	var img = _get_image_from_dict(path)
	img.lock()
	
	var rec_origin = Vector2(int(img.get_size().x * origin.x), int(img.get_size().y * origin.y))
	var rec_size = Vector2(int(img.get_size().x * size.x), int(img.get_size().y * size.y))
	
	var new_tex = img.get_rect(Rect2(rec_origin, rec_size))
	img.unlock()

	var new_tex_texture = ImageTexture.new()
	new_tex_texture.create_from_image(new_tex, _flags)
	
	return new_tex_texture


# Adds the image at the given path to the cache dictionary if it is not there yet.
func _load_into_dict_if_needed(path):
	_load_mutex.lock()
	if !_is_in_dict(path):
		_load_into_dict(path)
	_load_mutex.unlock()


# Adds the image at the given path to the cache dictionary as an ImageTexture.
func _load_into_dict(path):
	
	# Verify if there really is a file at that path
	if not path:
		logger.error("BUG: CachingImageTexture.gd:_load_into_dict was called with null as parameter")
		return
	
	# add the prefix to get the local full path
	var full_path = _full_path_prefix + path
	
	if not Directory.new().file_exists(full_path):
		logger.warning("An image was supposed to be loaded from %s, but this file does not exist!" % [full_path])
		return
	
	# Load the image from the path and create an ImageTexture from it
	var img = Image.new()
	img.load(full_path)
	if img.is_empty():  # check if the file was loaded correctly
		logger.warning("image %s could not be loaded - does it exist?" % [full_path])
	
	var img_tex = ImageTexture.new()
	img_tex.create_from_image(img, _flags)
	
	# Add to dictionary and return
	_path_imagetexture_dict[path] = [img_tex, img]


# Gets an ImageTexture from the cache dictionary using the given path.
# This means it can be used to texture objects.
func _get_texture_from_dict(path):
	if _is_in_dict(path):
		return _path_imagetexture_dict[path][0]
	else:
		return null


# Gets an Image from the cache dictionary using the given path.
# This means it can be manipulated (cropped, flipped, etc).
func _get_image_from_dict(path):
	if _is_in_dict(path):
		return _path_imagetexture_dict[path][1]
	else:
		return null


# Returns true if the image at the path is already in the cache dictionary.
func _is_in_dict(path):
	return _path_imagetexture_dict.has(path)
