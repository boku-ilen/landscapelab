extends RoadLane
class_name RoadLanePedestrian



func update_road_lane() -> void:
	self.road_height = 0.21
	super.update_road_lane()
	$RoadLanePolygon.material.set_shader_parameter("has_curbside_left", true)
	$RoadLanePolygon.material.set_shader_parameter("has_curbside_right", true)

func get_info() -> Dictionary:
	return {}
