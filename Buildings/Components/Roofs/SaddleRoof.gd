@tool
extends RoofBase


const type := TYPES.SADDLE

# Overhang factor
@export var roof_depth := 0.25
@export var texture_scale := Vector2(0.2, 0.2)

var height: float :
	set(new_height): height = new_height
var color: Color :
	set(new_color): color = new_color
var extent: float :
	set(new_extent): extent = new_extent
var center := Vector2(0,0): 
	set(new_center): center = new_center


func set_metadata(metadata: Dictionary):
	height = metadata["roof_height"]
	extent = metadata["extent"]


func can_build(geo_center, geo_footprint):
	return Geometry2D.is_point_in_polygon(geo_center, geo_footprint)


func build(footprint: PackedVector2Array):
	# Get the center of the footprint by averaging out all points
	var roof_height = height if height else min(extent / 5.0, 5.0)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate flat normals - shaded as if round otherwise
	st.set_smooth_group(-1)
	
	var sides = [
		footprint[1] - footprint[0],
		footprint[3] - footprint[2],
		footprint[2] - footprint[1],
		footprint[0] - footprint[3]]
	
	var lenghts1 = sides[0].length_squared() + sides[1].length_squared() 
	var lengths2 = sides[2].length_squared() + sides[3].length_squared()
	
	var footprint3d = [
		Vector3(footprint[0].x, 0, footprint[0].y),
		Vector3(footprint[1].x, 0, footprint[1].y),
		Vector3(footprint[2].x, 0, footprint[2].y),
		Vector3(footprint[3].x, 0, footprint[3].y)
	]
	
	# Create the roof top vertices in the middle of building depending on where the longer sides are
	var mid_vertices: Array[Vector2]
	if lenghts1 > lengths2:
		mid_vertices = [footprint[1] + sides[2] * 0.5, footprint[3] + sides[3] * 0.5]
	else:
		mid_vertices = [footprint[0] + sides[0] * 0.5, footprint[2] + sides[1] * 0.5]
		# Order is incorrect in this case => rotate first point
		footprint3d.insert(0, footprint3d.pop_back())
	
	var m0 = Vector3(mid_vertices[1].x, roof_height, mid_vertices[1].y)
	var m1 = Vector3(mid_vertices[0].x, roof_height, mid_vertices[0].y)
	
	var forward = m1.direction_to(m0)
	
	# We need 2 triangles for each saddle side
	# p1------m1------p2	# v1------v3------v4
	# |\      |\      | 	# |\      |\      |
	# | \     | \     | 	# | \     | \     |
	# |  \    |  \    | 	# |  \    |  \    |
	# |   \   |   \   | 	# |   \   |   \   |
	# |    \  |    \  | 	# |    \  |    \  | 
	# |     \ |     \ | 	# |     \ |     \ |
	# p0------m0------p3	# v0------v2------v5
	
	var vertices = [
		footprint3d[0], footprint3d[1], m0, m1, footprint3d[3], footprint3d[2]
	]
	
	# Create overhang over roof and scale with the extent of the building so
	# it adequatly fits the size of the building
	vertices[0] -= footprint3d[0].direction_to(vertices[2]) - forward #p0
	vertices[1] -= footprint3d[1].direction_to(vertices[3]) + forward #p1
	vertices[2] += forward # m0
	vertices[3] -= forward # m1
	vertices[4] -= footprint3d[3].direction_to(vertices[2]) - forward #p2
	vertices[5] -= footprint3d[2].direction_to(vertices[3]) + forward #p3
	
	var vertices_ordered = [
		vertices[0], vertices[1], vertices[3], vertices[5], vertices[4], vertices[2]
	]
	
	var uv_y = vertices[0].distance_to(vertices[2])
	var uv_x = vertices[0].distance_to(vertices[1])
	var uvs = [
		Vector2(uv_x, 0), Vector2(0, 0), Vector2(uv_x, uv_y),
		Vector2(0,uv_y), Vector2(uv_x, uv_y), Vector2(0, uv_y)
	]
	
	st.set_color(color)
	
	for idx in range(0, 3, 2):
		var directed_uvs: Array = uvs.map(func(uv): return -uv)
		uvs.reverse()
		
		_triangulate(st, vertices, directed_uvs, idx, idx + 1, idx + 2)
		_triangulate(st, vertices, directed_uvs, idx + 2, idx + 1, idx + 3)
	
	# Commit first surface (i.e. roof tiles)
	st.generate_normals()
	st.generate_tangents()
	var mesh = st.commit()
	
	# Clear - otherwise it will commit the previous meshes twice
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Add an underside for the roof
	# Go done to where the "volume" will be created
	var plane1 = Plane(vertices[2], vertices[1], vertices[3])
	var plane2 = Plane(vertices[2], vertices[3], vertices[5])
	
	var lowered_vertices = vertices.duplicate()
	
	lowered_vertices[0] -= plane1.normal * roof_depth 
	lowered_vertices[1] -= plane1.normal * roof_depth
	lowered_vertices[2] -= Vector3.UP * roof_depth
	lowered_vertices[3] -= Vector3.UP * roof_depth
	lowered_vertices[4] -= plane2.normal * roof_depth
	lowered_vertices[5] -= plane2.normal * roof_depth
	
	for idx in range(0, 3, 2):
		var directed_uvs: Array = uvs.map(func(uv): return -uv)
		directed_uvs = directed_uvs.map(func(uv: Vector2): return uv.rotated(PI/2))
		uvs.reverse()
		
		_triangulate(st, lowered_vertices, directed_uvs, idx + 2, idx + 1, idx)
		_triangulate(st, lowered_vertices, directed_uvs, idx + 3, idx + 1, idx + 2)
	
	# Reorder according to graphic (in order of triangles)
	vertices = [
		vertices[0], vertices[1], vertices[3], vertices[5], vertices[4], vertices[2]
	]
	lowered_vertices = [
		lowered_vertices[0], lowered_vertices[1], lowered_vertices[3], lowered_vertices[5], lowered_vertices[4], lowered_vertices[2]
	]
	
	# Give some volume to the roof (otherwise it looks like a sheet strechted over the footprint)
	for idx in vertices.size():
		var next_idx = (idx + 1) % vertices.size()
		
		uv_x = vertices[idx].distance_to(vertices[next_idx])
		uv_y = vertices[idx].distance_to(lowered_vertices[idx])
		uvs = Vector2(uv_x, uv_y) * texture_scale
		
		st.set_uv(Vector2(uvs.x, uvs.y))
		st.add_vertex(lowered_vertices[next_idx])
		st.set_uv(Vector2(0., 0.))
		st.add_vertex(vertices[idx])
		st.set_uv(Vector2(0., uvs.y))
		st.add_vertex(lowered_vertices[idx])
		
		st.set_uv(Vector2(uvs.x, 0.))
		st.add_vertex(vertices[next_idx])
		st.set_uv(Vector2(0., 0.))
		st.add_vertex(vertices[idx])
		st.set_uv(Vector2(uvs.x, uvs.y))
		st.add_vertex(lowered_vertices[next_idx])
	
	# Create a wall where the triangle of the saddle roof leaves an open space
	uv_x = footprint3d[0].distance_to(footprint3d[3])
	uv_y = ((footprint3d[0] + footprint3d[3]) / 2).distance_to(m0)
	_triangulate(st, 
		[footprint3d[0], m0, footprint3d[3]], 
		[Vector2(0,0), Vector2(uv_x/2, uv_y), Vector2(uv_x, 0)])
	_triangulate(st, 
		[footprint3d[2], m1, footprint3d[1]], 
		[Vector2(0,0), Vector2(uv_x/2, uv_y), Vector2(uv_x, 0)])
	
	st.generate_normals()
	st.generate_tangents()

	mesh = st.commit(mesh)
	mesh.custom_aabb = st.get_aabb()
	
	get_node("Roof").mesh = mesh
	
	vertices = vertices_ordered
	
		# We need 2 triangles for each saddle side
		# p1------m1------p2
		# |\      |\      |
		# | \     | \     |
		# |  \    |  \    |
		# |   \   |   \   |
		# |    \  |    \  |
		# |     \ |     \ |
		# p0------m0------p3
	var edges = []
	var directed_graph = {
		#vertices[0]: [vertices[1]],
		#vertices[1]: [vertices[2]],
		vertices[2]: [vertices[1], vertices[3], vertices[5]],
		#vertices[3]: [vertices[4]],
		vertices[4]: [vertices[5]],
		vertices[5]: [vertices[0]]
	}
	create_ridge_caps(directed_graph, color)


func _triangulate(st, vertices, uvs, idx0=0, idx1=1, idx2=2):
	st.set_uv(uvs[idx0] * texture_scale)
	st.add_vertex(vertices[idx0])
	st.set_uv(uvs[idx1] * texture_scale)
	st.add_vertex(vertices[idx1])
	st.set_uv(uvs[idx2] * texture_scale)
	st.add_vertex(vertices[idx2])
