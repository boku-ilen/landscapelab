@tool
extends Node3D


#
# Root node for buildings.
# Holds general variables and builds all children.
# All children should be floors, containing at least a "build" function, and likely also a "height" variable.
#


var height: float
var footprint: PackedVector2Array

var roof: RoofBase : 
	set(new_roof): 
		roof = new_roof
		add_child(roof)

func set_metadata(metadata: Dictionary):
	height = metadata["height"]
	footprint = metadata["footprint"]


# Build this building by calling "build" checked all children.
func build():
	# To stack the floors checked top of each other, the total height must be remembered
	var next_floor_height_offset = 0
	
	for child in get_children():
		child.position.y += next_floor_height_offset
		
		if child.has_method("build"):
			child.build(footprint)
		
		if "height" in child:
			next_floor_height_offset += child.height


func apply_daytime_change(is_daytime):
	for child in get_children():
		if child.has_method("set_lights_enabled"):
			child.set_lights_enabled(not is_daytime)
