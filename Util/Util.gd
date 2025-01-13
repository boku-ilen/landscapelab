extends Node
class_name util


static func str_to_var_or_default(value: String, default):
	return str_to_var(value) if str_to_var(value) != null else default


static func rangef(start: float, stop: float, step: float):
	var range = range(start * 100000., stop * 100000., step * 100000.)
	return range.map(func(i): return float(i) / 100000.)
