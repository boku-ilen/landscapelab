@tool
extends Node3D


func _process(delta: float) -> void:
	var params = PhysicsShapeQueryParameters3D.new()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.transform = get_node("RemovalShape").global_transform
	params.shape = get_node("RemovalShape").shape
	
	var space_state = get_world_3d().direct_space_state
	var overlapping = space_state.intersect_shape(params)
	
	for thing in overlapping:
		thing.collider.get_parent().visible = false
