extends Spatial


func set_relative_transform(node: Node, relation_node: Node, t: Transform):
	global_transform = relation_node.global_transform * t


func get_relative_transform(node: Node, relation_node: Node):
	var t = transform
	
	while node != relation_node:
		node = node.get_parent_spatial()
		t *= node.transform
