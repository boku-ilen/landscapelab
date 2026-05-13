extends Node

#
# Global paths and caches relating to Vegetation image data.
#


const SPRITE_SIZE = 2048
const GROUND_TEXTURE_SIZE = 1024
const FADE_TEXTURE_SIZE = 1024

var plant_image_base_path = "res://Assets/Natural/Plants/Foliage/Textures/"
var ground_image_base_path = "res://Assets/Ground"

var plant_image_cache = {}
var plant_image_texture_cache = {}
var ground_image_cache = {}
var ground_image_mutex = Mutex.new()
