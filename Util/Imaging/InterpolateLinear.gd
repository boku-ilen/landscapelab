extends Spatial


#
# This script can be used for a path that gets set in the world to interpolate
# between two points so it does not go beneath the tiles.
#


var maximum_distance_between_points = Settings.get_setting("assets", "linear-max-distance")


# Adds points between points which are more than maximum_distance_between_points from each other.
# Example situation where this is necessary: A very long and straight road which goes over a hill: We need
#  to add points so that the road goes neatly along the curve of the hill, instead of straight through it.
func interpolate_points(point1, point2) -> Array:
	
	var interpolated_points: Array
	
	var current_point = point1
	# If the distance is too large, interpolate a point
	while true:
		var actual_distance = current_point.distance_squared_to(point2)
		var maximum_distance = pow(maximum_distance_between_points + 1, 2)
		
		if actual_distance > maximum_distance:
			# The direction is the vector from this point to the next one.
			var direction = (point2 - current_point).normalized()
			var new_point = current_point + direction * maximum_distance_between_points
				
			interpolated_points.append(new_point)
			current_point = new_point
		else:
			break
	
	return interpolated_points
