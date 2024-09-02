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
var mesh: Mesh
var is_billboard: bool


func _init(initial_id, initial_name, initial_image_type, initial_note,
		initial_density_per_m, initial_size_factor, initial_mesh, initial_is_billboard):
	self.id = initial_id
	self.name = initial_name
	self.image_type = initial_image_type
	self.note = initial_note
	self.density_per_m = initial_density_per_m
	self.size_factor = initial_size_factor
	self.mesh = initial_mesh
	self.is_billboard = initial_is_billboard
