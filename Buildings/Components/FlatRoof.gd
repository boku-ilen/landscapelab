@tool
extends Node3D


#
# A simple flat roof, created by triangulating the footprint.
#


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
	
	for index in polygon_indices:
		var vertex_2d = footprint[index]
		st.add_color(color)
		st.add_uv(vertex_2d * 0.1)
		st.add_vertex(Vector3(vertex_2d.x, 0, vertex_2d.y))
	
	st.generate_normals()
	
	# Apply
	var mesh = st.commit()
	get_node("MeshInstance3D").mesh = mesh
