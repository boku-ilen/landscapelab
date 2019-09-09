extends GroundedSpatial

#
# Draws a road with a given width along the given points.
#


onready var curve = get_node("Path").curve
onready var csg_road = get_node("Path/Road")


var width = 0
var height = 0


func _ready():
	set_height(0.5)


# Overwritten since we need to update the individual points, not just this node
func _place_on_ground():
	# FIXME: Workaround for order of execution not making curve available since the GroundedSpatial's _ready() is
	#  called before this one's
	if not curve:
		curve = get_node("Path").curve
	
	# Keep this node at y = 0 because the individual points are responsible for the height
	global_transform.origin.y = 0
	
	for point_index in range(0, curve.get_point_count()):
		var new_pos = WorldPosition.get_position_on_ground(curve.get_point_position(point_index))
		
		curve.set_point_position(point_index, new_pos)


# Modifies the road polygon to have a given width
func set_width(new_width):
	width = new_width
	
	csg_road.polygon[0].x = -width / 2
	csg_road.polygon[1].x = -width / 2
	csg_road.polygon[2].x = width / 2
	csg_road.polygon[3].x = width / 2


# Modifies the road polygon to have a given height
# That height is also extruded downwards as a safeguard against floating roads
func set_height(new_height):
	height = new_height
	
	csg_road.polygon[0].y = -height
	csg_road.polygon[1].y = height
	csg_road.polygon[2].y = height
	csg_road.polygon[3].y = -height


# Adds the given array of Vector3 points to the road's curve
func add_points(points: Array):
	for point in points:
		add_point(point)
	
	# Put the points on the ground
	_place_on_ground()


# Adds one Vector3 point to the road's curve
func add_point(point: Vector3):
	curve.add_point(point)
