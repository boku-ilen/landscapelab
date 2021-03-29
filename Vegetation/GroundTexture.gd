extends Object
class_name GroundTexture

#
# Definition of a Ground Texture as assigned to a PlantGroup. Essentially a collection of textures
# (albedo, normal, etc.) along with some metadata such as the size.
#


var id: int
var texture_name: String
var type: String
var size_m: float
var seasons: Seasons
var description: String
var applications: String

func _init(id, texture_name, type, size_m, seasons, description, applications):
	self.id = id
	self.texture_name = texture_name
	self.type = type
	self.size_m = size_m
	self.seasons = seasons
	self.description = description
	self.applications = applications


class Seasons:
	var spring: bool
	var summer: bool
	var fall: bool
	var winter: bool
	
	func _init(spring: bool, summer: bool, fall: bool, winter: bool):
		self.spring = spring
		self.summer = summer
		self.fall = fall
		self.winter = winter
