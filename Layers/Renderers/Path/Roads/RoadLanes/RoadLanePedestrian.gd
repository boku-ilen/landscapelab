extends RoadLane
class_name RoadLanePedestrian



func update_road_lane() -> void:
	#self.road_height = 0.21
	super.update_road_lane()
	#$RoadLanePolygon.material.set_shader_parameter("has_curbside_left", true)
	#$RoadLanePolygon.material.set_shader_parameter("has_curbside_right", true)


func reset_custom_values() -> void:
	super.reset_custom_values()


func get_info() -> Array:
	var info = super.get_info()
	info.append_array([])
	return info
