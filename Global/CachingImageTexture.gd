extends Node

#
# This script allows ImageTextures to be loaded from any path in the filesystem, also outside the project directory.
# It caches every loaded image so that it doesn't load an image from the same path twice.
#

var _path_imagetexture_dict: Dictionary = {}

# Returns the image at the given path as an ImageTexture.
# If the image has been loaded before, it is returned from the cache dictionary.
func get(path):
	if !_is_in_dict(path):
		_load_into_dict(path)
		
	return _get_from_dict(path)

# Adds the image at the given path to the cache dictionary as an ImageTexture.
func _load_into_dict(path):
	# Load the image from the path and create an ImageTexture from it
	var img = Image.new()
	img.load(path)
	var img_tex = ImageTexture.new()
	img_tex.create_from_image(img, 8)
	
	# Add to dictionary and return
	_path_imagetexture_dict[path] = img_tex

# Gets an ImageTexture from the cache dictionary using the given path.
func _get_from_dict(path):
	return _path_imagetexture_dict[path]

# Returns true if the image at the path is already in the cache dictionary.
func _is_in_dict(path):
	return _path_imagetexture_dict.has(path)
