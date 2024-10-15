@tool
extends Node3D
class_name RoofBase


@export var roof_mesh: Node3D

var fid: int
var addon_layers: Dictionary # String to GeoLayer
var addon_objects: Dictionary # String to Object
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
	_fid,
	_addon_layers: Dictionary, 
	_addon_objects: Dictionary,
	_building_metadata: Dictionary):
	
	fid = _fid
	addon_layers = _addon_layers
	addon_objects = _addon_objects
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


func _create_edge_meshes(
	directed_graph: Dictionary,
	mesh: Mesh, 
	_transform:=Transform3D.IDENTITY, 
	color=null,
	extend_factor:=1.0):
	for start_node in directed_graph:
		for connected_node in directed_graph[start_node]:
			var mesh_inst = MeshInstance3D.new()
			var edge = Edge3.new(start_node, connected_node)
			mesh_inst.mesh = mesh.duplicate()
			
			var mdt = MeshDataTool.new()
			mdt.create_from_surface(mesh_inst.mesh, 0)
			for i in range(mdt.get_vertex_count()):
				mdt.set_vertex_uv(i, Vector2(mdt.get_vertex_uv(i).x, mdt.get_vertex_uv(i).y * edge.get_length() * 3.572 / 1.5))
				if color: mdt.set_vertex_color(i, color)
			
			mdt.commit_to_surface(mesh_inst.mesh)
			
			add_child(mesh_inst)
			mesh_inst.transform = edge.get_transform()
			mesh_inst.position = edge.get_center() 
			mesh_inst.position += _transform.origin * edge.get_transform().basis
			mesh_inst.transform.basis *= _transform.basis
			mesh_inst.scale.z = edge.get_length() / mesh_inst.mesh.get_aabb().size.z * extend_factor


func create_ridge_caps(directed_graph: Dictionary, color: Color):
	_create_edge_meshes(
		directed_graph, 
		preload("res://Buildings/Components/Roofs/Resources/RidgeCapMesh.tres"), 
		Transform3D.IDENTITY.translated(Vector3.UP * 0.2).scaled(Vector3(0.25,0.1,0.2)),
		color)


func create_gutters(directed_graph: Dictionary, color: Color):
	_create_edge_meshes(
		directed_graph, 
		preload("res://Buildings/Components/Roofs/Resources/Gutters.res"), 
		Transform3D.IDENTITY.translated(Vector3(0., 0.8, 0.)).scaled(Vector3(0.25,-0.2,0.2)),
		color,
		1.01)
