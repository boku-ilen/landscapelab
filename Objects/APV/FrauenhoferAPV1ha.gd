extends Spatial


var center
var height_layer
var height_unchanged = false


func set_height(origin):
	if height_unchanged: return
	
	for child in get_children():
		for apv in child.get_children():
			var pos_x = center[0] + origin.x + child.translation.x + apv.translation.x
			var pos_y = center[1] - origin.z - child.translation.z - apv.translation.z
			var height = height_layer.get_value_at_position(pos_x, pos_y)
			
			apv.translation.y = height
	
	height_unchanged = true
