@tool
extends RoofBase


#
# A pointed roof created by spanning triangles to the center of the polygon.
#

const type := TYPES.POINTED 

# Overhang factor
@export var roof_overhang_size := 1.75
var height: float
var color: Color
var extent: float
var center := Vector2(0,0)

var uv_scale = -0.25

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
	
	var point_center = Vector3(center.x, roof_height, center.y)
	var footprint3d = Array(footprint).map(func(vert: Vector2): return Vector3(vert.x, 0, vert.y))
	# Create overhang over roof and scale with the extent of the building so
	# it adequatly fits the size of the building
	footprint3d = footprint3d.map(func(vert: Vector3): return vert + (vert - point_center) * roof_overhang_size / extent)
	footprint3d.reverse()
	
	for index in range(footprint.size()):
		var point_current = footprint3d[index]
		var point_next = footprint3d[(index + 1) % footprint.size()]
		
		var distance_to_next_point
		var distance_to_center_point
		
		distance_to_next_point = max(0.1, point_current.distance_to(point_next)) # to prevent division by 0
		distance_to_center_point = max(0.1, ((point_current + point_next) / 2).distance_to(point_center)) # to prevent division by 0
		
		st.set_color(color)
		
		st.set_uv(Vector2(0.0, 0.0) * uv_scale)
		st.add_vertex(point_current)
		
		st.set_uv(Vector2(distance_to_next_point / 2, distance_to_center_point) * uv_scale)
		st.add_vertex(point_center)
		
		st.set_uv(Vector2(distance_to_next_point, 0.0) * uv_scale)
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
	
	var graph = {
		point_center: footprint3d
	}
	create_ridge_caps(graph, color)
	
	# Apply
	var mesh = st.commit()
	mesh.custom_aabb = st.get_aabb()
	get_node("MeshInstance3D").mesh = mesh
