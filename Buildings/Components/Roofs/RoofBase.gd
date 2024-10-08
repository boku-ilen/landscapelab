@tool
extends Node3D
class_name RoofBase


@export var roof_mesh: Node3D

var addon_layers: Dictionary # String to GeoLayer
var addon_objects: Dictionary # String to Object
var addons: Dictionary
var building_metadata: Dictionary

enum TYPES {
	FLAT,
	SADDLE,
	POINTED
}

class Edge3:
	var from: Vector3
	var to: Vector3
	var edge: Vector3
	
	func _init(_from, _to) -> void:
		from = _from
		to = _to
		edge = to - from
	
	func get_center() -> Vector3:
		return (from + to) / 2
	
	func get_length() -> float:
		return abs(from.distance_to(to))
	
	func get_transform() -> Transform3D:
		var t = Transform3D.IDENTITY
		t = t.translated(from).looking_at(to)
		return t
	
	func parallel_to(other: Edge3, epsilon: float):
		return (edge.dot(other.edge) / (edge.length() * other.edge.length())) > 1 - epsilon


# Use after instantiate as constructor
func with_data(
	_addon_layers: Dictionary, 
	_addon_objects: Dictionary, 
	_addons: Dictionary, 
	_building_metadata: Dictionary):
	
	addon_layers = _addon_layers
	addon_objects = _addon_objects
	addons = _addons
	building_metadata = _building_metadata
	return self


func set_metadata(metadata):
	return


func compute_vertex_directions_and_signs(footprint3d) -> Dictionary:
	var directions = []
	var signs = []
	directions.resize(footprint3d.size())
	signs.resize(footprint3d.size())
	for idx in footprint3d.size():
		# Create the outer vertices (where the plateaus will start from)
		var current_vert = footprint3d[idx]
		var prev_vert = footprint3d[(idx - 1) % footprint3d.size()]
		var next_vert = footprint3d[(idx + 1) % footprint3d.size()]
		
		if   current_vert == next_vert: next_vert = footprint3d[(idx + 2) % footprint3d.size()]
		elif current_vert == prev_vert: prev_vert = footprint3d[(idx - 2) % footprint3d.size()]
		
		var current_to_prev: Vector3 = current_vert.direction_to(prev_vert)
		var current_to_next: Vector3 = current_vert.direction_to(next_vert)
		
		var sign = sign(current_to_prev.signed_angle_to(current_to_next, Vector3.UP))
		var direction = (-current_to_prev - current_to_next).normalized()
		direction *= sign
		
		signs[idx] = sign
		directions[idx] = direction
	
	return {"directions": directions, "signs": signs}


func create_ridge_caps(directed_graph: Dictionary, color: Color):
	var offset_y = 0.1
	var mesh_scene = preload("res://Buildings/Components/Roofs/Resources/RidgeCap.res")
	for start_node in directed_graph:
		for connected_node in directed_graph[start_node]:
			var ridge_cap = MeshInstance3D.new()
			var edge = Edge3.new(start_node, connected_node)
			ridge_cap.mesh = mesh_scene.duplicate()
			
			var mdt = MeshDataTool.new()
			mdt.create_from_surface(ridge_cap.mesh, 0)
			for i in range(mdt.get_vertex_count()):
				mdt.set_vertex_uv(i, Vector2(mdt.get_vertex_uv(i).x, mdt.get_vertex_uv(i).y * edge.get_length() * 3.572 / 1.5))
				mdt.set_vertex_color(i, color)
			
			mdt.commit_to_surface(ridge_cap.mesh)
			
			add_child(ridge_cap)
			ridge_cap.transform = edge.get_transform()
			ridge_cap.position = edge.get_center() 
			ridge_cap.position.y += offset_y
			ridge_cap.scale /= 4
			ridge_cap.scale.z = edge.get_length() / 3.572
			
