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

var vertices := []
var point_center: Vector3


func set_metadata(metadata: BuildingMetadata):
	height = metadata.roof_height
	extent = metadata.extent


func can_build(geo_center, geo_footprint):
	return Geometry2D.is_point_in_polygon(geo_center, geo_footprint)


func build(footprint: PackedVector2Array):
	# Get the center of the footprint by averaging out all points
	height = height if height else min(extent / 5.0, 5.0)
	point_center = Vector3(center.x, height, center.y)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate flat normals - shaded as if round otherwise
	st.set_smooth_group(-1)
	
	var footprint3d = Array(footprint).map(func(vert: Vector2): return Vector3(vert.x, 0, vert.y))
	# Create overhang over roof and scale with the extent of the building so
	# it adequatly fits the size of the building
	footprint3d = footprint3d.map(func(vert: Vector3): return vert + (vert - point_center) * roof_overhang_size / extent)
	footprint3d.reverse()
	
	var result = compute_vertex_directions_and_signs(footprint3d)
	var directions = result["directions"].map(func(dir): return -dir)
	var signs = result["signs"]
	
	var outer_verts := []
	for idx in footprint3d.size():
		# Create the outer vertices (where the plateaus will start from)
		var current_vert = footprint3d[idx]
		var next_vert = footprint3d[(idx + 1) % footprint.size()]
		var prev_vert = footprint3d[(idx - 1) % footprint.size()]
		
		if   current_vert == next_vert: next_vert = footprint3d[(idx + 2) % footprint.size()]
		elif current_vert == prev_vert: prev_vert = footprint3d[(idx - 2) % footprint.size()]
		
		outer_verts.append(current_vert + directions[idx] * -roof_overhang_size / 16)
	
	var slates_vertices := []
	var slates_uvs := []
	var slates_colors := []
	var underroof_vertices := [] 
	var underroof_uvs := []
	var underroof_colors := []
	
	for index in range(outer_verts.size()):
		var point_current = outer_verts[index]
		var point_next = outer_verts[(index + 1) % footprint.size()]
		
		var distance_to_next_point
		var distance_to_center_point
		
		distance_to_next_point = max(0.1, point_current.distance_to(point_next)) # to prevent division by 0
		distance_to_center_point = max(0.1, ((point_current + point_next) / 2).distance_to(point_center)) # to prevent division by 0
		
		var uvs = GeometryUtil.project_triangle_to_uv(point_current, point_next, point_center)
		
		slates_uvs.append(uvs[0] * uv_scale)
		slates_vertices.append(point_current)
		slates_colors.append(color)
		
		slates_uvs.append(uvs[1] * uv_scale)
		slates_vertices.append(point_next)
		slates_colors.append(color)
		
		slates_uvs.append(uvs[2] * uv_scale)
		slates_vertices.append(point_center)
		slates_colors.append(color)
		
		var down_factor = 0.1
		# Give some volume to the roof (otherwise it looks like a sheet strechted over the footprint)
		underroof_uvs.append(Vector2(0,down_factor) * uv_scale)
		underroof_vertices.append(point_current + Vector3.DOWN * down_factor)
		underroof_colors.append(Color.GAINSBORO)
		underroof_uvs.append(Vector2(distance_to_next_point,down_factor) * uv_scale)
		underroof_vertices.append(point_next + Vector3.DOWN * down_factor)
		underroof_colors.append(Color.GAINSBORO)
		underroof_uvs.append(Vector2(0,0))
		underroof_vertices.append(point_current)
		underroof_colors.append(Color.GAINSBORO)
		
		underroof_uvs.append(Vector2(distance_to_next_point,down_factor) * uv_scale)
		underroof_vertices.append(point_next + Vector3.DOWN * down_factor)
		underroof_colors.append(Color.GAINSBORO)
		underroof_uvs.append(Vector2(distance_to_next_point,0) * uv_scale)
		underroof_vertices.append(point_next)
		underroof_colors.append(Color.GAINSBORO)
		underroof_uvs.append(Vector2(0,0) * uv_scale)
		underroof_vertices.append(point_current)
		underroof_colors.append(Color.GAINSBORO)
		
	var convexs = Geometry2D.decompose_polygon_in_convex(PackedVector2Array(outer_verts.map(func(vert): return Vector2(vert.x, vert.z))))
		
	for convex in convexs:
		var polygon_indices = Geometry2D.triangulate_polygon(convex)
		polygon_indices.reverse()
		for index in polygon_indices:
			var current_vertex_2d = convex[index]
			underroof_uvs.append(current_vertex_2d * -1.25)
			underroof_vertices.append(Vector3(current_vertex_2d.x, underroof_vertices[0].y, current_vertex_2d.y))
			underroof_colors.append(Color.GAINSBORO)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = slates_vertices
	arrays[Mesh.ARRAY_TEX_UV] = slates_uvs
	arrays[Mesh.ARRAY_COLOR] = slates_colors
	st.set_color(color)
	st.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	st.generate_normals()
	st.generate_tangents()
	var mesh = st.commit()
	
	arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = underroof_vertices
	arrays[Mesh.ARRAY_TEX_UV] = underroof_uvs
	arrays[Mesh.ARRAY_COLOR] = underroof_colors
	st.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	st.generate_normals()
	st.generate_tangents()
	mesh = st.commit(mesh)
	
	# Save for refine
	vertices = outer_verts
	
	# Apply
	mesh.custom_aabb = st.get_aabb()
	get_node("MeshInstance3D").mesh = mesh


func refine():
	var graph = {
		point_center: vertices
	}
	create_ridge_caps(graph, color)
	
	is_refined = true
