extends Node
class_name AbstractConnection

# Maximum length the distance can have - a value "-1" indicates there is no max
# length 
@export var max_length := -1.0
@export var load_radius := 500.0


# Abstract method: can be thread unsafe
func apply_connection():
	pass


# Abstract method: must be thread safe
func find_connection_points(_point_1: Vector3, _point_2: Vector3,
		_length_factor: float, _cache=null):
	pass
