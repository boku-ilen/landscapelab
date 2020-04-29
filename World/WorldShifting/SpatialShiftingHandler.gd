extends ShiftingHandler

#
# Handles the WorldShift of any normal Spatial with one 3D position.
#


func _handle_shift(spatial, delta_x, delta_z):
	assert(spatial is Spatial)
	
	spatial.translation.x += delta_x
	spatial.translation.z += delta_z
