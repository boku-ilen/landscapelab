tool
extends Spatial


#
# A pointed roof created by spanning triangles to the center of the polygon.
#


var height
var color


func _ready():
	$MeshInstance.material_override = preload("res://Buildings/Components/PointedRoof.tres")


func set_color(new_color):
	color = new_color


func get_center(footprint: PoolVector2Array):
	# TODO: Consider caching the result, can be called repeatedly (first can_build, then build)
	var center = Vector2.ZERO
	
	for vector in footprint:
		center += vector
	
	center /= footprint.size()
	
	return center


func set_height(new_height):
	height = new_height


func can_build(footprint):
	return Geometry.is_point_in_polygon(get_center(footprint), footprint)


func build(footprint: PoolVector2Array):
	# Get the center of the footprint by averaging out all points
	var center = get_center(footprint)
	
	# Get the extent for calculating a good height
	var min_vec = Vector2(INF, INF)
	var max_vec = Vector2(-INF, -INF)
	
	for vector in footprint:
		if vector.x < min_vec.x:
			min_vec.x = vector.x
		if vector.x > max_vec.x:
			max_vec.x = vector.x
		
		if vector.y < min_vec.y:
			min_vec.y = vector.y
		if vector.y > max_vec.y:
			max_vec.y = vector.y
	
	var extent = (max_vec - min_vec).length()
	var roof_height = height if height else min(extent / 5.0, 5.0)
		
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for index in range(footprint.size()):
		var vertex_2d = footprint[index]
		var next_2d = footprint[(index + 1) % footprint.size()]
		
		var point1 = Vector3(vertex_2d.x, 0, vertex_2d.y)
		var point2 = Vector3(next_2d.x, 0, next_2d.y)
		var point3 = Vector3(center.x, roof_height, center.y)
		
		var tangent_plane = Plane(point1, point2, point3)
		st.add_tangent(tangent_plane)
		st.add_color(color)
		
		st.add_uv(Vector2(0, 0))
		st.add_vertex(point1)
		
		st.add_uv(Vector2(1, 0))
		st.add_vertex(point2)
		
		st.add_uv(Vector2(0.5, 1))
		st.add_vertex(point3)
		# TODO: Set UV variables
	
	st.generate_normals()
	
	# Apply
	var mesh = st.commit()
	get_node("MeshInstance").mesh = mesh
