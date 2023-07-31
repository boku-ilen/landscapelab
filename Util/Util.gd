extends Node
class_name util


static func str_to_var_or_default(value: String, default):
	return str_to_var(value) if str_to_var(value) != null else default
