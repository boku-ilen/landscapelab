extends Node
class_name util


static func str_to_var_or_default(value: String, default):
	return str_to_var(value) if str_to_var(value) != null else default


static func rangef(start: float, stop: float, step: float):
	var range = range(start * 10000, stop * 10000, step * 10000)
	return range.map(func(i): return i / 10000)
