extends Object
class_name CurveHeightGetters


class AbstractCurveHeightGetter extends Object:
	var curve: Curve3D
	var height_layer: GeoRasterLayer
	var center: Array
	var height_curve: GeoFeatureLayer
	
	func _init(initial_curve, initial_height_layer, initial_center):
		curve = initial_curve
		height_layer = initial_height_layer
		center = initial_center
	
	# To be implemented by derived classes
	func get_height(offset):
		return 0.0
	
	func get_angle(offset):
		return 0.0


# Returns precise height regardless of the underlying curve.
class ExactCurveHeightGetter extends AbstractCurveHeightGetter:
	func get_height(offset):
		var position = curve.sample_baked(offset)
		
		return height_layer.get_value_at_position(
			center[0] + position.x,
			center[1] - position.z,
		)
	
	func get_angle(offset):
		var next_offset = offset + 1.0  # TODO: To we want this 1.0 to be modifyable?
		
		return atan((get_height(offset) - get_height(next_offset)) / (next_offset - offset))


# Linearly interpolates the height between the height at the last vertex and the height at the next
#  vertex.
class LerpedVertexCurveHeightGetter extends AbstractCurveHeightGetter:
	var distance_to_height = []
	
	func _init(initial_curve, initial_height_layer, initial_center):
		super._init(initial_curve, initial_height_layer, initial_center)
		
		for vertex_id in range(curve.point_count):
			var current_point = curve.get_point_position(vertex_id)
			var current_height = height_layer.get_value_at_position(
				center[0] + current_point.x,
				center[1] - current_point.z,
			)
			var current_distance = curve.get_closest_offset(current_point)
			
			distance_to_height.append([current_distance, current_height])
	
	func get_height(offset):
		# Get the closest two points to lerp between
		var previous_height := 0.0
		var next_height := 0.0
		var lerp_factor := 0.0
		
		for distance_height_index in range(distance_to_height.size()):
			if distance_to_height[distance_height_index][0] >= offset:
				previous_height = distance_to_height[distance_height_index - 1][1]
				next_height = distance_to_height[distance_height_index][1]
				
				var previous_offset = distance_to_height[distance_height_index - 1][0]
				var next_offset = distance_to_height[distance_height_index][0]
				lerp_factor = inverse_lerp(previous_offset, next_offset, offset)
				
				break
		
		return lerp(previous_height, next_height, lerp_factor)
	
	# FIXME: Lots of code duplication with get_height
	func get_angle(offset):
		# Get the closest two points to lerp between
		var previous_height := 0.0
		var next_height := 0.0
		
		var next_offset := 0.0
		var previous_offset := 0.0
		
		for distance_height_index in range(distance_to_height.size()):
			if distance_to_height[distance_height_index][0] >= offset:
				previous_height = distance_to_height[distance_height_index - 1][1]
				next_height = distance_to_height[distance_height_index][1]
				
				previous_offset = distance_to_height[distance_height_index - 1][0]
				next_offset = distance_to_height[distance_height_index][0]
				
				break
		
		return atan((previous_height - next_height) / (next_offset - previous_offset))


# Linearly interpolates the height between the height at the first point of the curve and the height
#  at the last point of the curve.
class LerpedLineCurveHeightGetter extends AbstractCurveHeightGetter:
	var first_point
	var last_point
	var length
	var height_at_first
	var height_at_last
	
	func _init(initial_curve, initial_height_layer, initial_center):
		super._init(initial_curve, initial_height_layer, initial_center)
		
		first_point = curve.get_point_position(0)
		last_point = curve.get_point_position(curve.get_point_count() - 1)
		length = curve.get_baked_length()
		
		height_at_first = height_layer.get_value_at_position(center[0] + first_point.x, center[1] - first_point.z)
		height_at_last = height_layer.get_value_at_position(center[0] + last_point.x, center[1] - last_point.z)
		
	func get_height(offset):
		return lerp(height_at_first, height_at_last, offset / length)
	
	func get_angle(offset):
		return atan((height_at_first - height_at_last) / length)
