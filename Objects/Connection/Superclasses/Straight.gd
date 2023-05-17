extends AbstractConnection


var engine_line = Curve3D.new()


func apply_connection():
	$Line.curve = engine_line


func find_connection_points(_point_1: Vector3, _point_2: Vector3,
		_length_factor: float, _cache=null):
	
	# Avoid "_find_interval: Zero length interval."
	if _point_1.is_equal_approx(_point_2):
		_point_1 += _point_1 * .01
		_point_2 -= _point_2 * .01
		
	engine_line.add_point(_point_1)
	engine_line.add_point(_point_2)
	return []
