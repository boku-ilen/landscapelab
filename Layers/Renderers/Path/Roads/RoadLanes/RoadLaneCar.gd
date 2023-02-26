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
var lanes: int = 2

var speed_forward: float = 0.0
var speed_backwards: float = 0.0
var lanes_forward: int = 0.0
var lanes_backwards: int = 0.0


func update_road_lane() -> void:
	super.update_road_lane()
	$RoadLanePolygon.material.set_shader_parameter("lanes", lanes)

func get_info() -> Dictionary:
	var info = super.get_info()
	info.merge({
		"Base Type": str(BASE_TYPE_TO_NAME[base_type]),
		"Physical Type": str(PHYSICAL_TYPE_TO_NAME[physical_type]),
		"Number of Lanes": str(lanes),
	})
	return info
