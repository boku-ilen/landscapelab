extends AbstractConnection


var engine_line = Curve3D.new()


func apply_connection():
	$Line.curve = engine_line


func find_connection_points(_point_1: Vector3, _point_2: Vector3,
		_length_factor: float, _cache=null):
	
	# Should the points be (almost) equal there is no need for a connection
	# as it would not be seen anyways
	if _point_1.is_equal_approx(_point_2):
		engine_line.add_point(_point_1)
		return []
	
	engine_line.add_point(_point_1)
	engine_line.add_point(_point_2)
	return []
