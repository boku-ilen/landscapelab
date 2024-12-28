@tool
extends RoofBase


#
# Usually Flat Roofs of modern buildings are built like
# 
# Birds eye: 
# __________
# |##########|
# |#        #|
# |#        #|
# |##########|
# 
# Where the "#" are some form of small plateau before descending into the middle
# part where the flat roof is filled with some form of pebbles

const type := TYPES.FLAT

@export var height := 0.2
@export var offset := 0.2
@export var inset := Vector2(1., 0.4)

var uv_scale = 0.25

var color


func set_color(new_color):
	color = new_color


func build(footprint: PackedVector2Array):
	var footprint3d: Array = Array(footprint).map(func(vert): return Vector3(vert.x, 0, vert.y))
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate flat normals - shaded as if round otherwise
	st.set_smooth_group(-1)
	st.set_color(color)
	
	var outer_verts := []
	
	var result = compute_vertex_directions_and_signs(footprint3d)
	var directions = result["directions"]
	var signs = result["signs"]
	
	for idx in footprint3d.size():
		# Create the outer vertices (where the plateaus will start from)
		var current_vert = footprint3d[idx]
		var prev_vert = footprint3d[(idx - 1) % footprint.size()]
		var next_vert = footprint3d[(idx + 1) % footprint.size()]
		
		if   current_vert == next_vert: next_vert = footprint3d[(idx + 2) % footprint.size()]
		elif current_vert == prev_vert: prev_vert = footprint3d[(idx - 2) % footprint.size()]
		
		outer_verts.append(current_vert + directions[idx] * offset)
	
	for idx in outer_verts.size():
		var distance_to_next = outer_verts[idx].distance_to(outer_verts[(idx + 1) % outer_verts.size()])
		var inner_dist = footprint3d[idx].distance_to(footprint3d[(idx + 1) % footprint3d.size()])
		var offset_uv = (inner_dist - distance_to_next) / 2
		
		var next_idx = (idx + 1) % footprint3d.size()
		st.set_uv(Vector2(0, 0) * uv_scale)
		st.add_vertex(outer_verts[idx])
		st.set_uv(Vector2(-offset_uv, offset_uv) * uv_scale)
		st.add_vertex(footprint3d[idx])
		st.set_uv(Vector2(distance_to_next, 0) * uv_scale)
		st.add_vertex(outer_verts[next_idx])
		
		st.set_uv(Vector2(distance_to_next, 0) * uv_scale)
		st.add_vertex(outer_verts[next_idx])
		st.set_uv(Vector2(-offset_uv, offset_uv) * uv_scale)
		st.add_vertex(footprint3d[idx])
		st.set_uv(Vector2(distance_to_next + offset_uv, offset_uv) * uv_scale)
		st.add_vertex(footprint3d[next_idx])
	
	var inner_verts := []
	for idx in outer_verts.size():
		# Give plateaus some height
		var distance_to_next = outer_verts[idx].distance_to(outer_verts[(idx + 1) % outer_verts.size()])
		st.set_uv(Vector2(0, 0) * uv_scale)
		st.add_vertex(outer_verts[idx])
		st.set_uv(Vector2(distance_to_next, 0) * uv_scale)
		st.add_vertex(outer_verts[(idx + 1) % outer_verts.size()])
		st.set_uv(Vector2(distance_to_next, height) * uv_scale)
		st.add_vertex(outer_verts[(idx + 1) % outer_verts.size()] + Vector3.UP * height)
		
		st.add_vertex(outer_verts[(idx + 1) % outer_verts.size()] + Vector3.UP * height)
		st.set_uv(Vector2(0, height) * uv_scale)
		st.add_vertex(outer_verts[idx] + Vector3.UP * height)
		st.set_uv(Vector2(0, 0) * uv_scale)
		st.add_vertex(outer_verts[idx])
		
		# Create the inner vertices (where the plateaus end)
		var current_vert = outer_verts[idx] + Vector3.UP * height
		var prev_vert = outer_verts[(idx - 1) % outer_verts.size()] + Vector3.UP * height
		var next_vert = outer_verts[(idx + 1) % outer_verts.size()] + Vector3.UP * height
		
		if   current_vert == next_vert: next_vert = outer_verts[(idx + 2) % outer_verts.size()] + Vector3.UP * height
		elif current_vert == prev_vert: prev_vert = outer_verts[(idx - 2) % outer_verts.size()] + Vector3.UP * height
		
		inner_verts.append(current_vert - directions[idx] * inset.x)
		
	outer_verts = outer_verts.map(func(vert): return vert + Vector3.UP * height)
	
	
	# Plateaus
	for idx in inner_verts.size():
		var outer_distance = outer_verts[idx].distance_to(outer_verts[(idx + 1) % outer_verts.size()])
		var inner_distance = inner_verts[idx].distance_to(inner_verts[(idx + 1) % inner_verts.size()])
		
		var offset_uv = (inner_distance - outer_distance) / 2
		
		var sign_change = 1.
		if is_equal_approx(inner_distance, outer_distance):
			offset_uv = (inner_verts[idx].x - outer_verts[idx].x) * -signs[idx]
			sign_change = -1.
		
		var next_idx = (idx + 1) % footprint.size()
		st.set_uv(Vector2(-offset_uv, offset_uv) * uv_scale)
		st.add_vertex(inner_verts[idx])
		st.set_uv(Vector2(0, 0) * uv_scale)
		st.add_vertex(outer_verts[idx])
		st.set_uv(Vector2(outer_distance, 0) * uv_scale)
		st.add_vertex(outer_verts[next_idx])
		
		st.add_vertex(outer_verts[next_idx])
		st.set_uv(Vector2(outer_distance + offset_uv * sign_change, offset_uv) * uv_scale)
		st.add_vertex(inner_verts[next_idx])
		st.set_uv(Vector2(-offset_uv, offset_uv) * uv_scale)
		st.add_vertex(inner_verts[idx])
		
	# Descend
	for idx in inner_verts.size():
		var next_idx = (idx + 1) % footprint.size()
		var distance_to_next = outer_verts[idx].distance_to(outer_verts[(idx + 1) % outer_verts.size()])
		
		st.set_uv(Vector2.ZERO * uv_scale)
		st.add_vertex(inner_verts[idx])
		st.set_uv(Vector2(distance_to_next, 0) * uv_scale)
		st.add_vertex(inner_verts[next_idx])
		st.set_uv(Vector2(distance_to_next, -inset.y) * uv_scale)
		st.add_vertex(inner_verts[next_idx] - Vector3.UP * inset.y)
		
		st.add_vertex(inner_verts[next_idx] - Vector3.UP * inset.y)
		st.set_uv(Vector2(0, -inset.y) * uv_scale)
		st.add_vertex(inner_verts[idx] - Vector3.UP * inset.y)
		st.set_uv(Vector2(0,0) * uv_scale)
		st.add_vertex(inner_verts[idx])
	
	st.generate_normals()
	st.generate_tangents()
	var mesh = st.commit()
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Fill
	var convexs = Geometry2D.decompose_polygon_in_convex(PackedVector2Array(inner_verts.map(func(vert): return Vector2(vert.x, vert.z))))
	
	if convexs.is_empty(): return false # The function may fail, printing "Convex decomposing failed!"
	
	for convex in convexs:
		var polygon_indices = Geometry2D.triangulate_polygon(convex)
		for index in polygon_indices:
			var current_vertex_2d = convex[index]
			st.set_uv(current_vertex_2d * 0.1)
			st.add_vertex(Vector3(current_vertex_2d.x, height-inset.y, current_vertex_2d.y))
	
	st.generate_normals()
	st.generate_tangents()
	mesh = st.commit(mesh)
	
	mesh.custom_aabb = st.get_aabb()
	get_node("MeshInstance3D").mesh = mesh
	
	return true


func can_refine(): return false
