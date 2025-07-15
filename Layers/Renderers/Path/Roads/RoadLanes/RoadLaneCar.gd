extends RoadLane
class_name RoadLaneCar

const BASE_TYPE_TO_NAME: Dictionary = {
	-1:		"Unknown",
	0:		"Country Road",
	1:		"Municipal Road",
	2:		"Private Road",
	3:		"Pedestrian",
	4:		"Bike Lane",
	5:		"Bike and Pedestrian Lane"
}

const PHYSICAL_TYPE_TO_NAME: Dictionary = {
	-1:		"Unknown",
	0:		"Autobahn",
	1:		"Divided Roadway",
	2:		"Undivided Roadway",
	3:		"Roundabout",
	4:		"Footpath",
	5:		"Bike and Pedestrian Lane",
	6:		"Bike Lane"
}

# Car lane info
var base_type: int = 0
var physical_type: int = 0
var number_of_lanes: int = 2

var speed_forward: float = 0.0
var speed_backwards: float = 0.0
var lanes_forward: int = 0
var lanes_backwards: int = 0

var custom_number_of_lanes: int = 0


func update_road_lane() -> void:
	super.update_road_lane()
	
	var lane_number = max(lanes_forward, 0) + max(lanes_backwards, 0)
	# Don't render lanes for thin roads, these likely don't have markings
	if road_width < 6.0:
		lane_number = 1
	$RoadLanePolygon.material.set_shader_parameter("lanes", lane_number)
	
	var lid := 2002
	$RoadLanePolygon.material.set_shader_parameter("lid_color", Color8(
		lid % 255,
		floor(lid / 255),
		0
	))
	
	$RoadLanePolygon.material.set_shader_parameter("banquet_width", max(road_width / 6.0, 1.2))
	
	# Don't draw outer lines for thin roads
	if road_width < 8.0:
		$RoadLanePolygon.material.set_shader_parameter("draw_outer_lines", false)


func reset_custom_values() -> void:
	super.reset_custom_values()
	custom_number_of_lanes = 0


func get_info() -> Array:
	var info = super.get_info()
	info.append_array([
		RoadInfoData.new("Base Type", BASE_TYPE_TO_NAME[base_type], "", false),
		RoadInfoData.new("Physical Type", PHYSICAL_TYPE_TO_NAME[physical_type], "", false),
		RoadInfoData.new("Number of Lanes", number_of_lanes, "", true, self, "custom_number_of_lanes"),
	])
	return info
