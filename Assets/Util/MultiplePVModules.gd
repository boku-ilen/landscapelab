tool
extends MoveableObject

# 
# Automatically builds a large PV plant with a given number of rows and
# columns of individual PV modules.
# Note that the resulting rows and columns can be off by 1 to preserve
# symmetry.
# 

export(int) var rows
export(int) var cols

export(float) var row_spacing
export(float) var col_spacing

var mesh = load("res://Assets/Util/PVMesh.tscn")

var terrain: Spatial

onready var pickup_shape = get_node("PickupBody/CollisionShape")


# Called when the node enters the scene tree for the first time.
func _ready():
	# Spawn rows * cols PV modules
	# Add 1 to make sure we get an odd number - asymmetry otherwise
	for row in range(-rows / 2, rows / 2 + 1):
		for col in range(-cols / 2, cols / 2 + 1):
			var new_scene = mesh.instance()
			
			new_scene.translation.x += col * col_spacing
			new_scene.translation.z += row * row_spacing
			
			add_child(new_scene)
	
	# Change the size of the PickupBody accordingly
	pickup_shape.shape.extents.x = cols / 2 * col_spacing
	pickup_shape.shape.extents.z = rows / 2 * row_spacing
