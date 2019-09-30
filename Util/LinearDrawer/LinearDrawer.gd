extends GroundedSpatial

#
# Draws a road with a given width along the given points.
#


onready var path = get_node("Path")
onready var curve = path.curve
onready var csg_road = get_node("Path/Road")


var width = 0
var height = 0


func _ready():
	set_height(1)


# Overwritten since we need to update the individual points, not just this node
func _place_on_ground():
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


# Modifies the road polygon to have a given width
func set_width(new_width):
	for child in path.get_children():
		if child is LinearCSGPolygon:
			child.set_width(new_width)
		else:
			logger.warning("Children of the path of a LinearDrawer should all be LinearCSGPolygons!")
	
	set_height(new_width / 5)


# Modifies the road polygon to have a given height
# That height * 2 is also extruded downwards as a safeguard against floating roads
func set_height(new_height):
	for child in path.get_children():
		if child is LinearCSGPolygon:
			child.set_height(new_height)
		else:
			logger.warning("Children of the path of a LinearDrawer should all be LinearCSGPolygons!")


# Adds the given array of Vector3 points to the road's curve
func add_points(points: Array):
	for point in points:
		add_point(point)
	
	# Put the points on the ground
	_place_on_ground()


# Adds one Vector3 point to the road's curve
func add_point(point: Vector3):
	curve.add_point(point)
