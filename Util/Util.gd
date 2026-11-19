extends Node
class_name util


static func str_to_var_or_default(value: String, default):
	return str_to_var(value) if str_to_var(value) != null else default


## Replaces every "$name$" occurrence in formula with resolve.call(name) and
## evaluates the result as an Expression.
## resolve must return the replacement text for each name, e.g.
## func(name): return "(%f)" % float(get_attribute(name))
static func evaluate_formula(formula: String, resolve: Callable) -> Variant:
	var formated_string = formula
	while formated_string.find("$") >= 0:
		var begin_index = formated_string.find("$")
		var end_index = formated_string.find("$", begin_index + 1)
		if end_index < 0:  # Unpaired trailing "$"
			logger.warn("Unpaired '$' in formula: %s" % formula)
			return 0.0
		var name = formated_string.substr(begin_index + 1, end_index - begin_index - 1)
		var value_string = resolve.call(name)
		formated_string = formated_string.left(begin_index) + value_string + formated_string.right(-(end_index + 1))
	
	var expression = Expression.new()
	var parse_result = expression.parse(formated_string)
	var result = expression.execute()
	
	if parse_result != OK or expression.has_execute_failed():
		logger.warn("Parse error with expression: %s" % formated_string)
		return 0.0
	
	return result


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
			child_aabb.position += child.position
			summed_aabb = summed_aabb.merge(child_aabb)
	
	return summed_aabb
