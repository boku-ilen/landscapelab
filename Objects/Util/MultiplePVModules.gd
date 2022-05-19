extends Spatial

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

var mesh = load("res://Objects/Util/PVMesh.tscn")

var render_info
var center


# Called when the node enters the scene tree for the first time.
func _ready():
	# Spawn rows * cols PV modules
	# Add 1 to make sure we get an odd number - asymmetry otherwise
	for row in range(-rows / 2, rows / 2 + 1):
		for col in range(-cols / 2, cols / 2 + 1):
			var new_scene = mesh.instance()
			add_child(new_scene)
			
			new_scene.translation.x += col * col_spacing
			new_scene.translation.z += row * row_spacing
	
	set_child_positions()
	set_notify_transform(true)


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		set_child_positions()


func set_child_positions():
	for child in get_children():
		var offset = render_info.ground_height_layer.get_value_at_position(
				center[0] + (transform.origin.x + child.translation.x),
				center[1] - (transform.origin.z + child.translation.z)) - transform.origin.y
		child.translation.y = offset
		
		var right_add = 2.0
		
		var offset_right = render_info.ground_height_layer.get_value_at_position(
				center[0] + (transform.origin.x + child.translation.x),
				center[1] - (transform.origin.z + child.translation.z - right_add)) - transform.origin.y
		
		var difference = offset_right - offset
		var diagonal_vector = Vector2(right_add, difference)
		
		child.rotation.x = diagonal_vector.angle()
		
#		var offset_up = ground_height_layer.get_value_at_position(
#				center[0] + (transform.origin.x + child.translation.x + right_add),
#				center[1] - (transform.origin.z + child.translation.z)) - transform.origin.y
#
#		difference = offset_up - offset
#		diagonal_vector = Vector2(right_add, difference)
#
#		child.rotation.z = -(diagonal_vector.angle())
