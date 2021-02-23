extends Spatial


#
# Displays the extent of the LabTable map as a transparent box mesh.
#


var HEIGHT = 20000  # TODO: Setting
var SYMBOL_THICKNESS = 150  # TODO: Setting

onready var labtable_extent = get_node("LabTableExtent") as MeshInstance

# The minimap symbol is hollow inside so that it only shows the outline
onready var labtable_extent_symbol = get_node("LabTableExtentSymbol") as CSGBox
onready var labtable_extent_symbol_inside = get_node("LabTableExtentSymbol/Inside") as CSGBox


func _ready():
	visible = false


# Set the extent of the mesh which displays the LabTable extent.
# Must receive engine coordinates.
func set_mesh_extent(top_left: Vector3, bottom_right: Vector3):
	var size = Vector3(abs(top_left.x - bottom_right.x), HEIGHT, abs(top_left.z - bottom_right.z))
	
	var center = bottom_right - (size / 2)
	center.y = 0
	center.z += size.z
	
	transform.origin = center
	
	labtable_extent.mesh.size = size
	
	labtable_extent_symbol.width = size.x
	labtable_extent_symbol.height = size.y
	labtable_extent_symbol.depth = size.z
	
	# Hollow out the labtable extent symbol with another slightly smaller cube
	# It would make more sense if we had to subtract SYMBOL_THICKNESS here, but I believe the size
	#  is negative because of the format of the coordinates in the engine vs on the server
	labtable_extent_symbol_inside.width = size.x - SYMBOL_THICKNESS
	labtable_extent_symbol_inside.height = size.y + 100
	labtable_extent_symbol_inside.depth = size.z - SYMBOL_THICKNESS
