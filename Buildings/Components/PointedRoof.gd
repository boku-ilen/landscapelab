extends RoofBase


#
# A pointed roof created by spanning triangles to the center of the polygon.
#


# Overhang factor
@export var roof_overhang_size := 1.75
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
	$MeshInstance3D.material_override = preload("res://Buildings/Components/PointedRoof.tres")


func can_build(geo_center, geo_footprint):
	return Geometry2D.is_point_in_polygon(geo_center, geo_footprint)


func build(footprint: PackedVector2Array):
	# Get the center of the footprint by averaging out all points
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
	mesh.custom_aabb = st.get_aabb()
	get_node("MeshInstance3D").mesh = mesh
