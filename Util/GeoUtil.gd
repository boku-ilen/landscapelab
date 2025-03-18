extends Resource
class_name GeoUtil


static func sample_points_on_height_model(points: Array, height_model: GeoRasterLayer, add_z_value:=false):
	for i in points.size():
		var point = points[i]
		var x = point.x
		var z = point.y if point is Vector2 else point.z
		
		var sample = height_model.get_value_at_position(x, -z)
		if point is Vector3: 
			var weird_val = point.y
			sample += weird_val
			if i > 5000: 
				var t
		
		var sampled_point = point
		sampled_point.y = sample
		points[i] = sampled_point
	
	return points
