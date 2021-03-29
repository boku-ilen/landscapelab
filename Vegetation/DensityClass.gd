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

# TODO: This influences the rendering of the DensityClass, but it is not really part of the
#  DensityClass definition, rather it is a PC-specific setting. Should it be moved?
var extent = 30.0 # FIXME: Placeholder value

func _init(id, name, image_type, note, density_per_m):
	self.id = id
	self.name = name
	self.image_type = image_type
	self.note = note
	self.density_per_m = density_per_m
