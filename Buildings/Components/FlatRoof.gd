extends Node3D


#
# A simple flat roof, created by triangulating the footprint.
#


@export var height = 0.5
var color


func _ready():
	$MeshInstance3D.material_override = preload("res://Buildings/Components/FlatRoof.tres")


func set_color(new_color):
	color = new_color


func build(footprint: PackedVector2Array):
	# Convert the footprint to a polygon
	var polygon_indices = Geometry2D.triangulate_polygon(footprint)
	
	if polygon_indices.is_empty():
		# The triangualtion was unsuccessful
		return
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate flat normals - shaded as if round otherwise
	st.set_smooth_group(-1)
	
	# Create flat roof
	for index in polygon_indices:
		var current_vertex_2d = footprint[index]
		st.set_color(color)
		st.set_uv(current_vertex_2d * 0.1)
		
		st.add_vertex(Vector3(current_vertex_2d.x, height, current_vertex_2d.y))
	
	# Create a little bit of height for the roof
	for index in polygon_indices:
		var current_vertex_2d = footprint[index]
		var next_vertex_2d = footprint[(index + 1) % footprint.size()]
		st.set_color(color)
		
		var distance_to_next = current_vertex_2d.distance_to(next_vertex_2d)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(Vector3(current_vertex_2d.x, 0, current_vertex_2d.y))
		st.set_uv(Vector2(0, height))
		st.add_vertex(Vector3(current_vertex_2d.x, height, current_vertex_2d.y))
		st.set_uv(Vector2(distance_to_next, 0))
		st.add_vertex(Vector3(next_vertex_2d.x, 0, next_vertex_2d.y))
		
		st.set_uv(Vector2(distance_to_next, height))
		st.add_vertex(Vector3(next_vertex_2d.x, height, next_vertex_2d.y))
		st.set_uv(Vector2(distance_to_next, 0))
		st.add_vertex(Vector3(next_vertex_2d.x, 0, next_vertex_2d.y))
		st.set_uv(Vector2(0, height))
		st.add_vertex(Vector3(current_vertex_2d.x, height, current_vertex_2d.y))
	
	st.generate_normals()
	st.generate_tangents()
	
	# Apply
	var mesh = st.commit()
	get_node("MeshInstance3D").mesh = mesh
