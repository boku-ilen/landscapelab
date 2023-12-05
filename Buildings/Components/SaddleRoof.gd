extends Node3D



# Overhang factor
@export var roof_overhang_size := 1.75
@export var texture_scale := Vector2(3, 3)
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


func _ready():
	$Roof.material_override = preload("res://Buildings/Components/PointedRoof.tres")


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
		footprint[4] - footprint[3]]
	
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
	# p1------m1------p2
	# |\      |\      |
	# | \     | \     |
	# |  \    |  \    |
	# |   \   |   \   |
	# |    \  |    \  |
	# |     \ |     \ |
	# p0------m0------p3
	
	var vertices = [
		footprint3d[0], footprint3d[1], m0, m1, footprint3d[3], footprint3d[2]
	]
	
	# Create overhang over roof and scale with the extent of the building so
	# it adequatly fits the size of the building
	vertices[0] -= footprint3d[0].direction_to(vertices[2]) - forward
	vertices[1] -= footprint3d[1].direction_to(vertices[3]) + forward
	vertices[3] -= forward
	vertices[2] += forward
	vertices[4] -= footprint3d[3].direction_to(vertices[2]) - forward
	vertices[5] -= footprint3d[2].direction_to(vertices[3]) + forward
	
	# Prevent z fighting with walls
	vertices = vertices.map(func(vert): return vert + Vector3.UP * 0.05)
	
	var uvs = [
		Vector2(1,0), Vector2(0,0), Vector2(1,0.5),
		Vector2(0,0.5), Vector2(1,1), Vector2(0,1)
	]
	
	st.set_color(color)
	
	for idx in range(vertices.size() - 2):
		if idx % 2: _triangulate(st, vertices, uvs, idx, idx + 1, idx + 2)
		else: 		_triangulate(st, vertices, uvs, idx + 1, idx, idx + 2)
	
	#var distance_to_next_point = max(0.1, point_current.distance_to(point_next)) # to prevent division by 0
	
	
	# Reorder according to graphic
	vertices = [
		vertices[0], vertices[1], vertices[3], vertices[5], vertices[4], vertices[2]
	]
	# Give some volume to the roof (otherwise it looks like a sheet strechted over the footprint)
	for idx in vertices.size():
		var point_current = vertices[idx]
		var point_next = vertices[(idx + 1) % vertices.size()]
		st.set_uv(Vector2(0,0))
		
		st.set_color(Color.DIM_GRAY)
		st.add_vertex(point_current + Vector3.DOWN * 0.5)
		st.add_vertex(point_current)
		st.add_vertex(point_next + Vector3.DOWN * 0.5)

		st.add_vertex(point_next + Vector3.DOWN * 0.5)
		st.add_vertex(point_current)
		st.add_vertex(point_next)
	
	st.generate_normals()
	st.generate_tangents()
	
	# Apply
	var mesh = st.commit()
	mesh.custom_aabb = st.get_aabb()
	get_node("Roof").mesh = mesh
	
	# Create a wall where the triangle of the saddle roof leaves an open space
	_triangulate(st, 
		[footprint3d[0], m0, footprint3d[3]], [Vector2(0,0), Vector2(1, 1), Vector2(1, 0)])
	_triangulate(st, 
		[footprint3d[2], m1, footprint3d[1]], [Vector2(0,0), Vector2(1, 1), Vector2(1, 0)])
	
	st.generate_normals()
	st.generate_tangents()

	mesh = st.commit()
	mesh.custom_aabb = st.get_aabb()
	get_node("WallFill").mesh = mesh


func _triangulate(st, vertices, uvs, idx0=0, idx1=1, idx2=2):
	st.set_uv(uvs[idx0] * texture_scale)
	st.add_vertex(vertices[idx0])
	st.set_uv(uvs[idx1] * texture_scale)
	st.add_vertex(vertices[idx1])
	st.set_uv(uvs[idx2] * texture_scale)
	st.add_vertex(vertices[idx2])
