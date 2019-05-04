extends MeshInstance

# creates a triangle strip using the given points
func update_mesh(var points, var loop):
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	for b in points:
		surface_tool.add_vertex(b[0])
		surface_tool.add_vertex(b[1])
	if loop:
		surface_tool.add_vertex(points[0][0])
		surface_tool.add_vertex(points[0][1])
	
	mesh = surface_tool.commit()