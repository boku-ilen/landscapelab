extends Node
class_name util


static func str_to_var_or_default(value: String, default):
	return str_to_var(value) if str_to_var(value) != null else default


static func rangef(start: float, stop: float, step: float):
	var range = range(start * 100000., stop * 100000., step * 100000.)
	return range.map(func(i): return float(i) / 100000.)


static func get_summed_aabb(node: Node3D) -> AABB:
	var summed_aabb = AABB()
	if node is VisualInstance3D and not node.layers == 65536:  # Ignore LID meshes
		var aabb = node.get_aabb()
		summed_aabb = summed_aabb.merge(aabb)
	
	for child in node.get_children():
		if child is Node3D:
			var child_aabb = get_summed_aabb(child)
			summed_aabb = summed_aabb.merge(child_aabb)
	
	return summed_aabb
