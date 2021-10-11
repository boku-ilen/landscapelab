tool
extends Spatial


#
# A simple flat roof, created by triangulating the footprint.
#


func set_texture(texture):
	$MeshInstance.material_override.albedo_texture = texture


func build(footprint: PoolVector2Array):
	# Convert the footprint to a polygon
	var polygon_indices = Geometry.triangulate_polygon(footprint)
	
	if polygon_indices.empty():
		# The triangualtion was unsuccessful
		return
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for index in polygon_indices:
		var vertex_2d = footprint[index]
		st.add_vertex(Vector3(vertex_2d.x, 0, vertex_2d.y))
		# TODO: Set UV variables
	
	st.generate_normals()
	
	# Apply
	var mesh = st.commit()
	get_node("MeshInstance").mesh = mesh
