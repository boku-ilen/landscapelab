extends Spatial

export(Array, Vector2) var points
export(bool) var face = true
export(Color) var color = Color(255,171,171)
export(float,0,1) var face_alpha = 0.5

var border_width = 50

func _ready():
	
	# convert Vector2 to Vector3
	var pts = []
	for p in points:
		pts.append(Vector3(p.x, 0, p.y))
	
	# generate border points
	var border_pts = []
	var inner_pts = []
	var outer_pts = []
	for i in range(points.size()):
		var normal = (next_element(pts, i) - previous_element(pts, i)).normalized().cross(Vector3(0,1,0))
		
		var inner = pts[i] - normal * border_width
		var outer = pts[i] + normal * border_width
		border_pts.append([inner, outer])
		inner_pts.append(inner)
		outer_pts.append(outer)
	
	# TODO: if not face calculate border_pts for start and end differenlty
	
	get_node("PolygonEdge").update_mesh(border_pts, face)
	#if face:
	#	get_node("PolygonFace").update_mesh(inner_pts)


func previous_element(var elements, var i):
	if i == 0:
		 return elements[elements.size()-1]
	return elements[i-1]


func next_element(var elements, var i):
	return elements[(i + 1) % elements.size()]