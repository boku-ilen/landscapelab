extends Object
class_name DensityClass

var id: int
var name: String
var image_type: String
var note: String
var density_per_m: float

func _init(id, name, image_type, note, density_per_m):
	self.id = id
	self.name = name
	self.image_type = image_type
	self.note = note
	self.density_per_m = density_per_m
