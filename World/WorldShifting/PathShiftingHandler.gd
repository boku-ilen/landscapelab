extends ShiftingHandler

#
# Handles the WorldShift of any normal Spatial with one 3D position.
#


func _handle_shift(path, delta_x, delta_z):
	assert(path is Path)
	
	# Shift all points
	for point_id in range(0, path.curve.get_point_count()):
		var position = path.curve.get_point_position(point_id)
		position.x += delta_x
		position.z += delta_z
		
		path.curve.set_point_position(point_id, position)
