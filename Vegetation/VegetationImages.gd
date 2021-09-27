extends Node

#
# Global paths and caches relating to Vegetation image data.
#


const SPRITE_SIZE = 2048
const GROUND_TEXTURE_SIZE = 2048

var plant_image_base_path
var ground_image_base_path

var plant_image_cache = {}
var plant_image_texture_cache = {}
var ground_image_cache = {}
var ground_image_mutex = Mutex.new()
