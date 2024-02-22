@tool
extends Node3D

# 
# Automatically builds a large PV plant with a given number of rows and
# columns of individual PV modules.
# Note that the resulting rows and columns can be unchecked by 1 to preserve
# symmetry.
# 

@export var rows: int : 
	set(new_rows): 
		rows = new_rows
@export var cols: int : 
	set(new_cols): 
		cols = new_cols

@export var row_spacing: float :
	set(new_row_spacing):
		row_spacing = new_row_spacing
@export var col_spacing: float :
	set(new_col_spacing):
		col_spacing = new_col_spacing
@export var height: float :
	set(new_height):
		height = new_height
@export var angle_ns := false

@export var mesh := preload("res://Objects/PhotovoltaicPlant/GroundMountedPVUnit.tscn")
var plant_array: Array

var render_info
var center


func get_pv_children():
	return get_children().filter(func(object): return object.is_in_group("PV"))


func create_plants():
	for child in get_pv_children(): child.free()
	plant_array = []
	
	# Spawn rows * cols PV modules
	# Add 1 to make sure we get an odd number - asymmetry otherwise
	for row in range(-rows / 2, rows / 2 + 1):
		plant_array.append([])
		for col in range(-cols / 2, cols / 2 + 1):
			var new_scene = mesh.instantiate()
			plant_array[row + rows / 2].append(new_scene)
			add_child(new_scene)
			
			new_scene.position.x += col * col_spacing
			new_scene.position.z += row * row_spacing


func position_plants():
	for row in range(-rows / 2, rows / 2 + 1):
		for col in range(-cols / 2, cols / 2 + 1):
			var node = plant_array[row + rows / 2][col + cols / 2]
			node.position.x = col * col_spacing
			node.position.y = height
			node.position.z = row * row_spacing


func _ready():
	create_plants()
	
	set_child_positions()
	set_notify_transform(true)


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		set_child_positions()


func set_child_positions():
	for child in get_pv_children():
		var offset = render_info.ground_height_layer.get_value_at_position(
				center[0] + (transform.origin.x + child.position.x),
				center[1] - (transform.origin.z + child.position.z)) - transform.origin.y
		child.position.y = offset
		
		if (angle_ns):
			var right_add = 2.0
			
			var offset_right = render_info.ground_height_layer.get_value_at_position(
					center[0] + (transform.origin.x + child.position.x),
					center[1] - (transform.origin.z + child.position.z - right_add)) - transform.origin.y
			
			var difference = offset_right - offset
			var diagonal_vector = Vector2(right_add, difference)
			
			child.rotation.x = diagonal_vector.angle()
		
#		var offset_up = ground_height_layer.get_value_at_position(
#				center[0] + (transform.origin.x + child.position.x + right_add),
#				center[1] - (transform.origin.z + child.position.z)) - transform.origin.y
#
#		difference = offset_up - offset
#		diagonal_vector = Vector2(right_add, difference)
#
#		child.rotation.z = -(diagonal_vector.angle())
