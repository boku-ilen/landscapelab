class_name FootprintOperations
extends Node



static func resize(footprint: DirectedFootprint, offset: float):
	var expanded_verts = []
	for idx in footprint.vertices.size():
		# Create the outer vertices (where the plateaus will start from)
		var current_vert = footprint.vertices[idx]
		var prev_vert = footprint.vertices[(idx - 1) % footprint.size()]
		var next_vert = footprint.vertices[(idx + 1) % footprint.size()]
		
		if   current_vert == next_vert: next_vert = footprint[(idx + 2) % footprint.size()]
		elif current_vert == prev_vert: prev_vert = footprint[(idx - 2) % footprint.size()]
		
		expanded_verts.append(current_vert + directions_signs["directions"][idx] * offset)
	
	return expanded_verts


static func plateau(outer_verts: Array[Vector3], inner_verts: Array[Vector3]):
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


class DirectedFootprint:
	var vertices: Array[Vector3]
	var directions: Array[Vector3]
	var signs: Array[Vector3]
	
	func size():
		return vertices.size()
	
	func append():
		
	
	func _init(_vertices=[], _directions=[], _signs=[]) -> void:
		vertices = _vertices
		directions = _directions
		signs = _signs
