extends Node3D


#
# A pointed roof created by spanning triangles to the center of the polygon.
#


# Overhang factor
@export var roof_overhang_size := 1.75
var height
var color


func _ready():
	$MeshInstance3D.material_override = preload("res://Buildings/Components/PointedRoof.tres")


func set_color(new_color):
	color = new_color


func get_center(footprint: PackedVector2Array):
	# TODO: Consider caching the result, can be called repeatedly (first can_build, then build)
	var center = Vector2.ZERO
	
	for vector in footprint:
		center += vector
	
	center /= footprint.size()
	
	return center


func set_height(new_height):
	height = new_height


func can_build(footprint):
	return Geometry2D.is_point_in_polygon(get_center(footprint), footprint)


func build(footprint: PackedVector2Array):
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
	
	# Generate flat normals - shaded as if round otherwise
	st.set_smooth_group(-1)
	
	for index in range(footprint.size()):
		var vertex_2d = footprint[index]
		var next_2d = footprint[(index + 1) % footprint.size()]
		
		var point_current = Vector3(vertex_2d.x, 0, vertex_2d.y)
		var point_next = Vector3(next_2d.x, 0, next_2d.y)
		var point_center = Vector3(center.x, roof_height, center.y)
		
		# Create overhang over roof and scale with the extent of the building so
		# it adequatly fits the size of the building
		point_current -= (point_center - point_current) * roof_overhang_size / extent
		point_next -= (point_center - point_next) * roof_overhang_size / extent
		
		var distance_to_next_point = max(0.1, point_current.distance_to(point_next)) # to prevent division by 0
		
		st.set_color(color)
		
		var texture_scale = Vector2(1, 4) / 2
		st.set_uv(Vector2(0.0, 0.0) * texture_scale)
		st.add_vertex(point_current)
		
		st.set_uv(Vector2(distance_to_next_point / 2, height) * texture_scale)
		st.add_vertex(point_center)
		
		st.set_uv(Vector2(distance_to_next_point, 0.0) * texture_scale)
		st.add_vertex(point_next)
		
		# Give some volume to the roof (otherwise it looks like a sheet strechted over the footprint)
		st.set_color(Color.DIM_GRAY)
		st.add_vertex(point_current + Vector3.DOWN * 0.2)
		st.add_vertex(point_current)
		st.add_vertex(point_next + Vector3.DOWN * 0.2)
		
		st.add_vertex(point_next + Vector3.DOWN * 0.2)
		st.add_vertex(point_current)
		st.add_vertex(point_next)
	
	st.generate_normals()
	st.generate_tangents()
	
	# Apply
	var mesh = st.commit()
	get_node("MeshInstance3D").mesh = mesh
