extends Spatial


#
# Displays the extent of the Lego map as a transparent box mesh.
#


var HEIGHT = 20000  # TODO: Setting
var SYMBOL_THICKNESS = 50  # TODO: Setting

onready var lego_extent = get_node("LegoExtent") as MeshInstance

# The minimap symbol is hollow inside so that it only shows the outline
onready var lego_extent_symbol = get_node("LegoExtentSymbol") as CSGBox
onready var lego_extent_symbol_inside = get_node("LegoExtentSymbol/Inside") as CSGBox


func _ready():
	visible = false
	
	Offset.connect("shift_world", self, "_shift")


# Set the extent of the mesh which displays the Lego extent.
# Must receive engine coordinates.
func set_mesh_extent(top_left: Vector3, bottom_right: Vector3):
	var size = Vector3(top_left.x - bottom_right.x, HEIGHT, top_left.z - bottom_right.z)
	
	var center = top_left - (size / 2)
	center.y = 0
	
	transform.origin = center
	
	lego_extent.mesh.size = size
	
	lego_extent_symbol.width = size.x
	lego_extent_symbol.height = size.y
	lego_extent_symbol.depth = size.z
	
	# Hollow out the lego extent symbol with another slightly smaller cube
	# It would make more sense if we had to subtract SYMBOL_THICKNESS here, but I believe the size
	#  is negative because of the format of the coordinates in the engine vs on the server
	lego_extent_symbol_inside.width = size.x + SYMBOL_THICKNESS
	lego_extent_symbol_inside.height = size.y + 100
	lego_extent_symbol_inside.depth = size.z + SYMBOL_THICKNESS


# Move self accordingly when a world shift happens
func _shift(delta_x, delta_z):
	transform.origin.x += delta_x
	transform.origin.z += delta_z
