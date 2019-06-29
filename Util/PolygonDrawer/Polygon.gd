extends MeshInstance

#
# To be able to work with the gui instead of having to code all the properties of the meshinstance
# this scene was created. Also we use the shiftworld function
#


func _ready():
	Offset.connect("shift_world", self, "shift")

# Shift the player's in-engine translation by a certain offset, but not the player's true coordinates.
func shift(delta_x, delta_z):	
	translation.x += delta_x
	translation.z += delta_z
