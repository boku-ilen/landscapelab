extends AbstractConnection


export var A := 0.15
export var dA := 0.001
export var step_size := 20

const stepsize = 0.5
var catenary_curve: Array


func apply_connection():
	$Line.points = catenary_curve


func find_connection_points(P1: Vector3, P2: Vector3, length_factor: float):
	catenary_curve = _find_curve(P1, P2, length_factor)


# Catenary equations have to be performed numerically, follow these links for 
# extended info: https://en.wikipedia.org/wiki/Catenary, https://www.youtube.com/watch?v=gkdnS6rISV0&t=1092s
func _find_curve(_P1: Vector3, _P2: Vector3, length_factor: float) -> Array:
	# The point with higher x value should be P1
	if _P1.x < _P2.x: 
		var temp = _P2
		_P2 = _P1
		_P1 = temp
	
	# Map the 3D-space to a trivial 2D-example and store necessary 3D-information 
	# to transform back x and y coordinates in V1 and V2
	var V1 = Vector3(_P1.x, 0, _P1.z)
	var V2 = _P2-_P1
	V2.y = 0
	var P1 = Vector2(0, _P1.y)
	var P2 = Vector2(V2.length(), _P2.y)
	
	# Instead of a given a straight length (in which  case it is possible, that the 
	# length is not long enough to compute a catenary), we decided it would be wiser
	# to use a factor: factor=1.0 => distance from P1 to P2
	var L = P1.distance_to(P2) * length_factor
	assert(pow(L,2) > P1.distance_squared_to(P2)) 
	
	# Numerically solve the problem
	var curve = []
	
	var dx = P2.x - P1.x
	var xb = (P2.x + P1.x) / 2
	
	var dy = P2.y - P1.y
	var yb = (P2.y + P1.y) / 2
	
	var r = sqrt(pow(L, 2) - pow(dy, 2)) / dx
	
	var left = r * A
	var right = sinh(A)
	while left >= right:
		left = r * A
		right = sinh(A)
		A = A + dA
		
	A = A - dA
	var a = dx / (2*A)
	var b = xb - a * tanhi(dy / L)
	var c = P1.y - a * cosh((P1.x - b) / a)
	
	# With obtaining a, b and c we can find all the points on the curve,
	# the step-size specifies how accurate the curve should be
	var x = P1.x
	var y
	while x < P2.x:
		# The height of y will stay the same in 3D no matter x and z
		y = a * cosh((x - b) / a) + c
		# Map x and z coordinate back to 3D
		var xz: Vector3 = V1 + x / V2.length() * V2
		curve.append(Vector3(xz.x, y, xz.z))
		x += step_size
	
	# Since the "step_size" might leave a big whole from the last entry in "curve"
	# append another point exactly at P2
	y = a * cosh((P2.x - b) / a) + c
	var xz: Vector3 = V1 + P2.x / V2.length() * V2 
	curve.append(Vector3(xz.x, y, xz.z))
	
	return curve


func tanhi(z: float) -> float:
	return 0.5 * log((1 + z) / (1 - z))
