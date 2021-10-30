tool
extends Spatial


#
# Root node for buildings.
# Holds general variables and builds all children.
# All children should be floors, containing at least a "build" function, and likely also a "height" variable.
#


var height
var footprint: PoolVector2Array
var holes: Array

func set_footprint(new_footprint):
	footprint = new_footprint


func get_center():
	var count = 0
	var sum = Vector2.ZERO
	
	for vertex in footprint:
		sum += vertex
		count += 1
	
	sum /= count
	return Vector3(sum.x, 0.0, sum.y)


func set_holes(new_holes):
	holes = new_holes


# Offsets all vertices in the footprint by the given values.
func set_offset(offset_x: int, offset_y: int):
	for i in range(0, footprint.size()):
		footprint[i].x -= offset_x
		footprint[i].y -= offset_y
		
		# We need to adjust the y value because -z is forward in 3D.
		# TODO: This should really be somewhere else
		footprint[i].y = -footprint[i].y


# Build this building by calling "build" on all children.
func build():
	# To stack the floors on top of each other, the total height must be remembered
	var next_floor_height_offset = 0
	
	for child in get_children():
		child.translation.y += next_floor_height_offset
		
		if child.has_method("build"):
			child.build(footprint)
		
		if "height" in child:
			next_floor_height_offset += child.height


func set_lights_enabled(enabled):
	for child in get_children():
		if child.has_method("set_lights_enabled"):
			child.set_lights_enabled(enabled)
