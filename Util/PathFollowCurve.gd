extends Path3D
class_name PathFollowCurve

# The parent curve to follow
@export var curve_to_follow: Curve3D

@export var offset: float = 0.0
@export_range(0, 1) var start: float = 0.0
@export_range(0, 1) var end: float = 1.0


func update_curve() -> void:
	if curve_to_follow == null or curve_to_follow.point_count < 2:
		return
	
	var curve_length = curve_to_follow.get_baked_length()
	
	# Get start point
	var curve_offset: float = start * curve_length;
	var start_point: Vector3 = _get_offsetted_point(curve_to_follow, curve_offset, offset)
	var start_index = _get_curve_point_index(curve_to_follow, curve_offset)
	
	# Get end point
	curve_offset = end * curve_length;
	var end_point: Vector3 = _get_offsetted_point(curve_to_follow, curve_offset, offset)
	var end_index = _get_curve_point_index(curve_to_follow, curve_offset)
	
	# Set own curve
	self.curve = Curve3D.new()
	self.curve.add_point(start_point)
	
	# Add all points that are between start to end point
	for i in range(start_index, end_index):
		var curve_point = curve_to_follow.get_point_position(i)
		curve_offset = curve_to_follow.get_closest_offset(curve_point);
		var point = _get_offsetted_point(curve_to_follow, curve_offset, offset)
		self.curve.add_point(point)
	
	# Add last point
	self.curve.add_point(end_point)


func _get_offsetted_point(curve: Curve3D, curve_offset: float, h_offset: float) -> Vector3:
	var t: Transform3D = curve.sample_baked_with_rotation(curve_offset)
	var point = t.origin + (t.basis.x * h_offset)
	
	return point


func _get_curve_point_index(curve, offset):
	var curve_point_length = curve.get_point_count()
	if curve_point_length < 2:
		return curve_point_length
	for i in range(1, curve_point_length):
		var current_point_offset = curve.get_closest_offset(curve.get_point_position(i))
		if current_point_offset > offset: 
			return i
	return curve_point_length
