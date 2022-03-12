extends LinearCSGPolygon


# Modifies the the polygon to have a given width / height
func set_width(new_width: float):
	width = new_width
	
	polygon[0].x = -width / 2
	polygon[1].x = -width / 2
	polygon[2].x = width / 2
	polygon[3].x = width / 2


func set_height(new_height: float):
	height = new_height
	
	polygon[0].y = -height / 2
	polygon[1].y = height / 2
	polygon[2].y = height / 2
	polygon[3].y = -height / 2
