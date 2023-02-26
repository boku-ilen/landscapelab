extends PathFollowCurve
class_name RoadLane

const LANE_TYPE_TO_NAME: Dictionary = {
	-1:		"Unknown",
	0: 		"Car Lane",
	1: 		"Bike Lane",
	2: 		"Pedestrian Lane",
	3: 		"Parking Lane",
	4: 		"Multi-purpose Lane",
	5: 		"Bike and Pedestrian Lane",
}


# Road info
var lane_type: int = -1

# Road path info
var road_width: float = 2.0
var road_offset: float = 0.0
var road_height: float = 0.2
var percentage_from = 0.0
var percentage_to = 100.0

var road_curve: Curve3D

# Parent road instance
var road_instance: RoadInstance


func update_road_lane() -> void:
	var half_width = road_width / 2.0
	
	var polygon: PackedVector2Array = [
		Vector2(-half_width, road_height),
		Vector2(half_width, road_height),
		Vector2(half_width, 0.0),
		Vector2(-half_width, 0.0)
	]
	
	# Set polygon
	$RoadLanePolygon.polygon = polygon
	# Required for correct UV scaling
	$RoadLanePolygon.path_u_distance = road_width
	
	# Set underlying PathFollowCurve values
	self.curve_to_follow = road_curve
	self.offset = road_offset + (sign(road_offset) * half_width)
	self.start = percentage_from / 100.0
	self.end = percentage_to / 100.0
	self.update_curve()
	
	# Set shader variables
	$RoadLanePolygon.material.set_shader_parameter("width", road_width)
	$RoadLanePolygon.material.set_shader_parameter("height", road_height)



func get_info() -> Dictionary:
	return {
		"Lane Type": str(LANE_TYPE_TO_NAME[lane_type]),
		"Width": "%sm" %[road_width],
		"Offset": "%sm" %[road_offset],
		"Percentage from": "%s%%" %[snapped(percentage_from, 0.01)],
		"Percentage to": "%s%%" %[snapped(percentage_to, 0.01)],
	}
