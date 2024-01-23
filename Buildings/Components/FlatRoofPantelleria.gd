extends Node3D


#
# A simple flat roof, created by triangulating the footprint.
#


@export var height = 1.5
var color


func _ready():
	$MeshInstance3D.material_override = preload("res://Buildings/Components/FlatRoofPantelleria.tres")


func build(footprint: PackedVector2Array):
	# Convert the footprint to a polygon
	var polygon_indices = Geometry2D.triangulate_polygon(footprint)
	
	if polygon_indices.is_empty():
		# The triangualtion was unsuccessful
		return
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate flat normals if it is a complex building
	# Using smooth normals on complex buildings creates unwanted ligthing artifacts
	if footprint.size() > 7:
		st.set_smooth_group(-1)
	# Otherwise fake the increase the dome-ish look by smoothing the normals
	else:
		st.set_smooth_group(1)
	
	# Create dome-ish look by adding the heigher vertices offset inwards
	var downscaled_footprint = footprint * Transform2D(0, Vector2.ONE * 0.9, 0, Vector2.ZERO) 
	
	# Create flat roof
	var polygon_indices_rev = Geometry2D.triangulate_polygon(downscaled_footprint)
	polygon_indices_rev.reverse()
	for index in polygon_indices_rev:
		var current_vertex_2d = downscaled_footprint[index]
		st.set_color(Color.BEIGE)
		st.set_uv(current_vertex_2d * 0.1)
		st.add_vertex(Vector3(current_vertex_2d.x, height, current_vertex_2d.y))
	
	# Create a little bit of height for the roof
	for index in polygon_indices:
		var lower_current_vertex_2d = footprint[index]
		var higher_current_vertex_2d = downscaled_footprint[index]
		var lower_next_vertex_2d = footprint[(index + 1) % footprint.size()]
		var higher_next_vertex_2d = downscaled_footprint[(index + 1) % footprint.size()]
		st.set_color(Color.BEIGE)
		
		var distance_to_next = lower_current_vertex_2d.distance_to(lower_next_vertex_2d)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(Vector3(lower_current_vertex_2d.x, 0, lower_current_vertex_2d.y))
		st.set_uv(Vector2(0, height))
		st.add_vertex(Vector3(higher_current_vertex_2d.x, height, higher_current_vertex_2d.y))
		st.set_uv(Vector2(distance_to_next, 0))
		st.add_vertex(Vector3(lower_next_vertex_2d.x, 0, lower_next_vertex_2d.y))
		
		st.set_uv(Vector2(distance_to_next, height))
		st.add_vertex(Vector3(higher_next_vertex_2d.x, height, higher_next_vertex_2d.y))
		st.set_uv(Vector2(distance_to_next, 0))
		st.add_vertex(Vector3(lower_next_vertex_2d.x, 0, lower_next_vertex_2d.y))
		st.set_uv(Vector2(0, height))
		st.add_vertex(Vector3(higher_current_vertex_2d.x, height, higher_current_vertex_2d.y))
	
	st.generate_normals()
	st.generate_tangents()
	
	# Apply
	var mesh = st.commit()
	mesh.custom_aabb = st.get_aabb()
	get_node("MeshInstance3D").mesh = mesh
