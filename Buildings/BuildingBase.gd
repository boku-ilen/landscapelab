extends Node3D


#
# Root node for buildings.
# Holds general variables and builds all children.
# All children should be floors, containing at least a "build" function, and likely also a "height" variable.
#


var height: float :
	set(new_height): height = new_height
var footprint: PackedVector2Array : 
	set(new_footprint): footprint = new_footprint


func set_metadata(metadata: Dictionary):
	height = metadata["height"]
	footprint = metadata["footprint"]


# Offsets all vertices in the footprint by the given values.
func set_offset(offset_x: int, offset_y: int):
	for i in range(0, footprint.size()):
		footprint[i].x -= offset_x
		footprint[i].y -= offset_y
		
		# We need to adjust the y value because -z is forward in 3D.
		# TODO: This should really be somewhere else
		footprint[i].y = -footprint[i].y


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
