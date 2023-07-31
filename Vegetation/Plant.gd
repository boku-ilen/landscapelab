extends Object
class_name Plant

#
# Definition of a plant to be used in a PlantGroup. Provides access to the billboard image (texture)
# and metadata like the height.
#


# We assume all billboards to end with 'png' since they require transparency
const BILLBOARD_ENDING = ".png"

enum Size {XS, S, M, L, XL}
enum Season {SPRING, SUMMER, AUTUMN, WINTER}

var id: int
var billboard_path: String
var type: String
var size_class#: Size
var species: String
var name_en: String
var name_de: String
var season#: Season
var style: String
var color: String
var source: String
var license: String
var author: String
var note: String

var height_min: float
var height_max: float

var density_class
var density_ha: int
var cluster_per_ha: int
var plants_per_ha: int
var cluster_width: float

func _get_full_icon_path():
	return VegetationImages.plant_image_base_path.path_join("small-" + billboard_path) + BILLBOARD_ENDING

func _get_full_billboard_path():
	return VegetationImages.plant_image_base_path.path_join(billboard_path) + BILLBOARD_ENDING

func _load_into_cache_if_necessary(full_path):
	if not VegetationImages.plant_image_cache.has(full_path):
		# Load Image into the Image cache
		var img = load(full_path)
		
		if img.is_empty():
			logger.warn("Invalid billboard path in %s: %s"
					% [name_en, full_path])
		
		VegetationImages.plant_image_cache[full_path] = img


func _get_image(path):
	if not FileAccess.file_exists(path):
		logger.warn("Invalid Plant image (file does not exist): %s" % [path])
		return null
	
	_load_into_cache_if_necessary(path)
	return VegetationImages.plant_image_cache[path]

func _get_texture(path):
	if not FileAccess.file_exists(path):
		logger.warn("Invalid Plant image (file does not exist): %s" % [path])
		return null
	
	_load_into_cache_if_necessary(path)
	return VegetationImages.plant_image_texture_cache[path]

# Return the billboard of this plant as an unmodified Image.
func get_billboard():
	return _get_image(_get_full_billboard_path())

# Return an ImageTexture with the billboard of this plant.
func get_billboard_texture():
	return _get_texture(_get_full_billboard_path())

# Return an icon (a small version of the billboard) for this plant.
func get_icon():
	return _get_image(_get_full_icon_path())

# Return an ImageTexture with the icon of this plant.
func get_icon_texture():
	return _get_texture(_get_full_icon_path())

# Preload the billboard texture to increase run-time loading speeds at the cost of the initial loading speed
func preload_texture():
	_load_into_cache_if_necessary(_get_full_billboard_path())

# Return a string in the form "ID: Name (Size Class)"
func get_title_string():
	return str(self.id) + ": " + self.name_de \
			+ " (" + str(self.size_class) + ")"

