extends AbstractConnection


export var A := 0.015
export var dA := 0.001
export var line_step_size := 10

var catenary_curve: Array


class CatenaryCache:
	var curve: Array
	var prev_P1: Vector3
	var prev_P2: Vector3
	
	func _init(c, P1, P2):
		curve = c
		prev_P1 = P1
		prev_P2 = P2


func apply_connection():
	if catenary_curve:
		$Node/Line.curve = Curve3D.new()
		for point in catenary_curve:
			$Node/Line.curve.add_point(point)


func find_connection_points(P1: Vector3, P2: Vector3, length_factor: float, cache_array: Array = []):
	var cache_index = _get_cache(P1, P2, cache_array)
	if cache_index > -1:
		var cache = cache_array[cache_index] as CatenaryCache
		var offset = P1 - cache.prev_P1
		for i in range(cache.curve.size()):
			cache.curve[i] = cache.curve[i] + offset
		catenary_curve = cache.curve
	else:
		catenary_curve = _find_curve(P1, P2, length_factor)
	
	cache_array.append(CatenaryCache.new(catenary_curve.duplicate(true), P1, P2))
	
	return cache_array


# Returns -1 if no according cache could be found, index of cache else
func _get_cache(P1: Vector3, P2: Vector3, cache_array: Array):
	for i in range(cache_array.size()):
		var cache = cache_array[i] as CatenaryCache
		if cache and (P2 - P1 == cache.prev_P2 - cache.prev_P1):
			return i
	
	return -1


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
	var P1_2D = Vector2(0, _P1.y)
	var P2_2D = Vector2(V2.length(), _P2.y)

	# Instead of a given a straight length (in which  case it is possible, that the 
	# length is not long enough to compute a catenary), we decided it would be wiser
	# to use a factor: factor=1.0 => distance from P1 to P2
	var L = P1_2D.distance_to(P2_2D) + P1_2D.distance_to(P2_2D) * length_factor
	#assert(pow(L,2) > P1_2D.distance_squared_to(P2_2D)) 

	# Numerically solve the problem
	var curve = []

	var dx = P2_2D.x - P1_2D.x
	var xb = (P2_2D.x + P1_2D.x) / 2

	var dy = P2_2D.y - P1_2D.y
	var yb = (P2_2D.y + P1_2D.y) / 2

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
	var c = P1_2D.y - a * cosh((P1_2D.x - b) / a)

	# With obtaining a, b and c we can find all the points on the curve,
	# the step-size specifies how accurate the curve should be
	var x = P1_2D.x
	var y
	while x < P2_2D.x:
		# The height of y will stay the same in 3D no matter x and z
		y = a * cosh((x - b) / a) + c
		# Map x and z coordinate back to 3D
		var xz: Vector3 = V1 + x / V2.length() * V2
		curve.append(Vector3(xz.x, y, xz.z))
		x += line_step_size

	# Since the "step_size" might leave a big whole from the last entry in "curve"
	# append another point exactly at P2
	y = a * cosh((P2_2D.x - b) / a) + c
	var xz: Vector3 = V1 + P2_2D.x / V2.length() * V2 
	curve.append(Vector3(xz.x, y, xz.z))
	
	return curve


func tanhi(z: float) -> float:
	return 0.5 * log((1 + z) / (1 - z))
