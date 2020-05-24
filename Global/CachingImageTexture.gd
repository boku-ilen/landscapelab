extends Node

#
# This script allows ImageTextures to be loaded from any path in the filesystem, also outside the project directory.
# It caches every loaded image so that it doesn't load an image from the same path twice.
#

var _path_imagetexture_dict: Dictionary = {}
var _load_mutex: Mutex = Mutex.new()
var _flags: int = Settings.get_setting("caching-images", "default-flags")
# FIXME: this setting does not exist anymore. This request is resulting in an error message
var _full_path_prefix: String = Settings.get_setting("filesystem", "local-resources-path")


# Returns the image at the given path as an ImageTexture.
# If the image has been loaded before, it is returned from the cache dictionary.
# Optionally, different flags than the default can be given, e.g. to prevent filtering.
# The flags of the image should not be changed afterwards (it will also change in all
# other places the image is used since it's a reference!) - use get_new for this!
func get(path, flags=_flags):
	_load_into_dict_if_needed(path, flags)
		
	return _get_texture_from_dict(path)
	
	
# Get a fresh instance of an Image as an ImageTexture, which is not saved to the cache.
# This can be used to e.g. modify the flags in the new ImageTexture without affecting
# all other usages.
func get_new(path):
	_load_into_dict_if_needed(path)
	
	var img = ImageTexture.new()
	img.create_from_image(_get_image_from_dict(path))
	
	return img


# Adds the image at the given path to the cache dictionary if it is not there yet.
func _load_into_dict_if_needed(path, flags=_flags):
	_load_mutex.lock()
	if !_is_in_dict(path):
		_load_into_dict(path, flags)
	_load_mutex.unlock()


# Adds the image at the given path to the cache dictionary as an ImageTexture.
func _load_into_dict(path, flags):
	
	# Verify if there really is a file at that path
	if not path:
		logger.error("BUG: CachingImageTexture.gd:_load_into_dict was called with null as parameter")
		return
	
	# add the prefix to get the local full path
	var full_path = _full_path_prefix + "/" + path
	
	if not Directory.new().file_exists(full_path):
		logger.warning("An image was supposed to be loaded from %s, but this file does not exist!" % [full_path])
		return
	
	# Load the image from the path and create an ImageTexture from it
	var img = Image.new()
	img.load(full_path)
	if img.is_empty():  # check if the file was loaded correctly
		logger.warning("image %s could not be loaded - does it exist?" % [full_path])
	
	var img_tex = ImageTexture.new()
	img_tex.create_from_image(img, flags)
	
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
