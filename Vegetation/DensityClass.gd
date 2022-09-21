extends Object
class_name DensityClass

#
# Plants are put into Density Classes which control how densely they are rendered. Putting multiple
# plants into the same density class makes them share the total density, causing each plant's
# individual density to be reduced.
#


var id: int
var name: String
var image_type: String
var note: String
var density_per_m: float
var size_factor: float


func _init(id,name,image_type,note,density_per_m,size_factor):
	self.id = id
	self.name = name
	self.image_type = image_type
	self.note = note
	self.density_per_m = density_per_m
	self.size_factor = size_factor
