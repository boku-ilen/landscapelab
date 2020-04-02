extends GroundedSpatial
class_name LinearDrawer

#
# Draws a road with a given width along the given points.
#


export(bool) var grounded
export(float) var maximum_distance_between_points = 3.0


onready var path = get_node("Path")
onready var curve = path.curve
onready var csg_road = get_node("Path/Road")


var width = 0
var height = 0


func _ready():
	set_height(0.5)


# Overwritten since we need to update the individual points, not just this node
func _place_on_ground():
	if not grounded: return
	
	_just_placed_on_ground = true
	
	# FIXME: Workaround for order of execution not making curve available since the GroundedSpatial's _ready() is
	#  called before this one's
	if not curve:
		curve = get_node("Path").curve
	
	# Keep this node at y = 0 because the individual points are responsible for the height
	global_transform.origin.y = 0
	
	for point_index in range(0, curve.get_point_count()):
		var old_pos = curve.get_point_position(point_index)
		
		# For the new height, we need to add the global_transform.origin since we need the global position,
		#  but the position of the point should stay relative, so we only apply the y-coordinate
		var new_pos_y = WorldPosition.get_position_on_ground(global_transform.origin + old_pos).y
		
		var new_pos = Vector3(old_pos.x, new_pos_y, old_pos.z)
		curve.set_point_position(point_index, new_pos)


func _set_tilts():
	for point_index in range(0, curve.get_point_count()):
		# Calculate the tilt at this position
		var point = curve.interpolate(point_index, 0.0)
		var point2 = curve.interpolate(point_index, 0.01)
		var dir = (point2 - point).normalized()
		
		var normal = WorldPosition.get_normal_on_ground(point)
		normal.x = -normal.x  # TODO: Is this only required here or is the normal itself wrong?
		
		var dir_up_plane = Plane(dir.cross(Vector3.UP), 0.0)
		var dist = asin(dir_up_plane.distance_to(normal))
		
		# TODO: This is likely related to the scale of the normal map. Once that
		#  is synced with the tile size in meters, this will not be required anymore.
		dist *= 0.35
		
		# A high tilt means that the terrain here is more complex, which means it's
		#  likely that we intersect with it somewhere. Thus, move this point up a bit
		curve.set_point_position(point_index, point + Vector3.UP * abs(dist) * 7.0)
		
		curve.set_point_tilt(point_index, dist)


# Modifies the road polygon to have a given width
func set_width(new_width):
	for child in get_node("Path").get_children():
		if child is LinearCSGPolygon:
			child.set_width(new_width)
		else:
			logger.warning("Children of the path of a LinearDrawer should all be LinearCSGPolygons!")
	
	set_height(0.4 + min(new_width / 20, 0.5))


# Modifies the road polygon to have a given height
# That height * 2 is also extruded downwards as a safeguard against floating roads
func set_height(new_height):
	for child in get_node("Path").get_children():
		if child is LinearCSGPolygon:
			child.set_height(new_height)
		else:
			logger.warning("Children of the path of a LinearDrawer should all be LinearCSGPolygons!")


# Set the Curve3D of this drawer's path to a given new Curve3D directly
func set_curve(curve: Curve3D):
	get_node("Path").curve = curve
	
	if grounded:
		_interpolate_points(get_node("Path").curve)
		_place_on_ground()
		_set_tilts()


# Adds the given array of Vector3 points to the road's curve
func add_points(points: Array):
	for point in points:
		add_point(point)
	
	# Put the points on the ground
	if grounded:
		_place_on_ground()


# Adds one Vector3 point to the road's curve
func add_point(point: Vector3):
	get_node("Path").curve.add_point(point)


# Adds points between points which are more than maximum_distance_between_points from each other.
# Example situation where this is necessary: A very long and straight road which goes over a hill: We need
#  to add points so that the road goes neatly along the curve of the hill, instead of straight through it.
func _interpolate_points(curve: Curve3D):
	var done = true
	
	var point_id = 0
	
	while true:
		# If this point has no next point, we're done
		if point_id > curve.get_point_count() - 2:
			break
		
		var current_point = curve.get_point_position(point_id)
		var next_point = curve.get_point_position(point_id + 1)
		
		# If the distance is too large, interpolate a point
		if current_point.distance_squared_to(next_point) > pow(maximum_distance_between_points + 1, 2):
			# The direction is the vector from this point to the next one.
			var direction = (next_point - current_point).normalized()
			var new_point = current_point + direction * maximum_distance_between_points
			
			curve.add_point(new_point, Vector3.ZERO, Vector3.ZERO, point_id + 1)
			
		point_id += 1
