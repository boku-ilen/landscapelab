extends Node
class_name AbstractConnection


# Abstract method: can be thread unsafe
func apply_connection():
	pass


# Abstract method: must be thread safe
func find_connection_points(P1: Vector3, P2: Vector3, length_factor: float, cache=null):
	pass
