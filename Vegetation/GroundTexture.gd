extends Object
class_name GroundTexture

#
# Definition of a Ground Texture2D as assigned to a PlantGroup. Essentially a collection of textures
# (albedo, normal, etc.) along with some metadata such as the size.
#


var id: int
var texture_name: String
var type: String
var size_m: float = 0.0
var seasons: Seasons
var description: String
var applications: String

const MAX_SIZE_M := 128.0

func _init(initial_id, initial_texture_name, initial_type, initial_size_m,
		initial_seasons, initial_description, initial_applications):
	self.id = initial_id
	self.texture_name = initial_texture_name
	self.type = initial_type
	self.size_m = initial_size_m
	self.seasons = initial_seasons
	self.description = initial_description
	self.applications = initial_applications


class Seasons:
	var spring: bool
	var summer: bool
	var fall: bool
	var winter: bool
	
	func _init(initial_spring: bool, initial_summer: bool, initial_fall: bool,
			initial_winter: bool):
		self.spring = initial_spring
		self.summer = initial_summer
		self.fall = initial_fall
		self.winter = initial_winter
