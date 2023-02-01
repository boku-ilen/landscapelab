extends Node
class_name AbstractConnection


# Abstract method: can be thread unsafe
func apply_connection():
	pass


# Abstract method: must be thread safe
func find_connection_points(_point_1: Vector3, _point_2: Vector3,
		_length_factor: float, _cache=null):
	pass
