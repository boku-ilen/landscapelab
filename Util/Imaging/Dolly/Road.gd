extends LinearCSGPolygon


# Modifies the road polygon to have a given width
func set_width(new_width: float):
	width = new_width
	
	polygon[0].x = -width / 2
	polygon[1].x = -width / 2
	polygon[2].x = width / 2
	polygon[3].x = width / 2


# Modifies the road polygon to have a given height
# That height * 2 is also extruded downwards as a safeguard against floating roads
func set_height(new_height: float):
	height = new_height
	
	polygon[0].y = -height * 2
	polygon[1].y = height
	polygon[2].y = height
	polygon[3].y = -height * 2
