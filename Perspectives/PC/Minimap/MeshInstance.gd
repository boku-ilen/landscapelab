extends MeshInstance


func _ready():
	pass

func update_mesh(var points, var border_width):
	
	var surface_tool = SurfaceTool.new()
	
	
	# generate border points
	var pts = []
	for i in range(points.size()):
		var normal = (next_element(points, i) - previous_element(points, i)).cross(Vector3(0,1,0))
		
		pts.append([points[i] + normal * border_width, points[i] - normal * border_width])
	
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	for b in pts:
		surface_tool.add_vertex(b[0])
		surface_tool.add_vertex(b[1])
	surface_tool.add_vertex(pts[0][0])
	surface_tool.add_vertex(pts[0][1])


func previous_element(var elements, var i):
	if i == 0:
		 return elements[elements.size()-1]
	return elements[i-1]


func next_element(var elements, var i):
	elements[(i + 1) % elements.size()]