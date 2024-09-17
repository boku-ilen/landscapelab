@tool
extends Node3D
class_name RoofBase


@export var roof_mesh: Node3D

var addon_layers: Dictionary # String to GeoLayer
var addon_objects: Dictionary # String to Object
var addons: Dictionary
var building_metadata: Dictionary


class edge:
	var from: Vector3
	var to: Vector3
	
	func _init(_from, _to) -> void:
		from = _from
		to = _to
	
	func get_center() -> Vector3:
		return (from + to) / 2
	
	func get_length() -> float:
		return abs(from.distance_to(to))
	
	func get_transform() -> Transform3D:
		var t = Transform3D.IDENTITY
		t = t.translated(from).looking_at(to)
		return t


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


func create_ridge_caps(directed_graph: Dictionary, color: Color):
	var offset_y = 0.1
	var mesh_scene = preload("res://Buildings/Components/Roofs/Resources/RidgeCap.res")
	for start_node in directed_graph:
		for connected_node in directed_graph[start_node]:
			var ridge_cap = MeshInstance3D.new()
			var edge = edge.new(start_node, connected_node)
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
