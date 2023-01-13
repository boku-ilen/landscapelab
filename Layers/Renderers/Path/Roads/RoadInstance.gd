extends Path3D
class_name RoadInstance


const ROAD_HEIGHT = 0.2
const CURBSIDE_WIDTH = 0.05
const CURBSIDE_HEIGHT = 0.05

const type_to_names: Dictionary = {
	-1:		"Unknown",
	0:		"Country Road",
	1:		"Municipal Road",
	2:		"Private Road",
	3:		"Pedestrian",
	4:		"Bike Lane",
	5:		"Bike and Pedestrian Lane"
}

const physical_type_to_names: Dictionary = {
	-1:		"Unknown",
	0:		"Autobahn",
	1:		"Divided Roadway",
	2:		"Undivided Roadway",
	3:		"Roundabout",
	4:		"Footpath",
	5:		"Bike and Pedestrian Lane",
	6:		"Bike Lane"
}

const lane_type_to_name: Dictionary = {
	0: 		"Car Lane",
	1: 		"Bike Lane",
	2: 		"Pedestrian Lane",
	3: 		"Multi-purpose Lane",
	4: 		"Parking Lane",
	10: 	"Curbside"
}


# Road Information
var id: int
var road_name: String
var from_intersection: int
var to_intersection: int
var width: float
var length: float
var left_width: float
var right_width: float
var speed_forward: float
var speed_backwards: float
var lanes_forward: int
var lanes_backwards: int
var direction: int
var type: int           # e.g. country road or private road
var physical_type: int     # e.g. divided road or Autobahn
var lane_uses: String      # e.g. | bike | road | pedestrian |

# The id of the intersection this road comes from
var intersection_id: int

class RoadLane extends RefCounted:
	var type: int = -1
	var width: float = -1.0
	var offset: float = -1.0
	var height: float = -1.0


var road_lanes: Array = []

var bike_on_road: int = 0

func set_polygon_from_lane_uses() -> void:
	# Default road if no lanes are defined
	if lane_uses == null or lane_uses.is_empty():
		$CSGPolygon3D.polygon[0].x = -width / 2.0
		$CSGPolygon3D.polygon[0].y = ROAD_HEIGHT
		$CSGPolygon3D.polygon[1].x = width / 2.0
		$CSGPolygon3D.polygon[1].y = ROAD_HEIGHT
		$CSGPolygon3D.polygon[2].x = width / 2.0
		$CSGPolygon3D.polygon[2].y = 0
		$CSGPolygon3D.polygon[3].x = -width / 2.0
		$CSGPolygon3D.polygon[3].y = 0
		return
	
	var lanes: PackedStringArray = lane_uses.split(';', false)
	var bike_on_car_offset: float = 0
	var left_bike_on_road = false
	var right_bike_on_road = false
	for lane in lanes:
		var lane_infos: PackedStringArray = lane.split(',', false)
		var road_lane: RoadLane = RoadLane.new()
		road_lane.type = int(lane_infos[0])
		road_lane.width = float(lane_infos[1])
		road_lane.offset = float(lane_infos[2]) * -1
		
		if road_lane.type == 4:
			bike_on_car_offset += road_lane.width
			if road_lane.offset < 0:
				left_bike_on_road = true
			else:
				right_bike_on_road = true
		
		road_lanes.append(road_lane)
	
	for road_lane in road_lanes:
		if road_lane.type == 0:
			road_lane.width -= bike_on_car_offset
			break
	
	road_lanes.sort_custom(custom_compare)
	
	var lane_types = []
	var lane_widths = []
	
	var height = ROAD_HEIGHT
	var points: PackedVector2Array
	var number_of_lanes: int = 0
	var last_lane_end: float = 10000.0
	var last_lane: RoadLane = RoadLane.new()
	# Set upper points, defining road surface
	for road_lane in road_lanes:
		var current_lane_begin = road_lane.offset - road_lane.width / 2.0
		
		# Add curbside if going from sidewalk (bike or pedestrian) to road
		if road_lane.type == 0 or road_lane.type == 3 or road_lane.type == 4:
			if last_lane.type == 1 or last_lane.type == 2:
				# Add curbside point and flag it as curbside in shader
				points.insert(number_of_lanes, Vector2(current_lane_begin - CURBSIDE_WIDTH, height))
				lane_types.push_back(10)
				lane_widths.push_back(CURBSIDE_WIDTH)
				number_of_lanes += 1
				
				points.insert(number_of_lanes, Vector2(current_lane_begin, height))
				lane_types.push_back(10)
				lane_widths.push_back(CURBSIDE_WIDTH)
				number_of_lanes += 1
				
				# Correct road height as we are now lower due to curbside
				height -= CURBSIDE_HEIGHT
		
		# Add additional point if there is space in-between lanes
		if last_lane_end < current_lane_begin:
			points.insert(number_of_lanes, Vector2(last_lane_end, height))
			lane_types.push_back(-1)
			lane_widths.push_back(-1)
			number_of_lanes += 1
		
		# Add curbside if going from road to sidewalk (bike or pedestrian) 
		if road_lane.type == 1 or road_lane.type == 2:
			if last_lane.type == 0 or last_lane.type == 3 or last_lane.type == 4:
				# Correct road height as we are now lower due to curbside
				height += CURBSIDE_HEIGHT
				
				points.insert(number_of_lanes, Vector2(last_lane_end, height))
				lane_types.push_back(10)
				lane_widths.push_back(CURBSIDE_WIDTH)
				number_of_lanes += 1
				
				points.insert(number_of_lanes, Vector2(last_lane_end + CURBSIDE_WIDTH, height))
				lane_types.push_back(10)
				lane_widths.push_back(CURBSIDE_WIDTH)
				number_of_lanes += 1
		
		
		# Add current lane point
		points.insert(number_of_lanes, Vector2(current_lane_begin, height))
		lane_types.push_back(road_lane.type)
		lane_widths.push_back(road_lane.width / 2.0)
		last_lane_end = road_lane.offset + road_lane.width / 2.0
		
		last_lane = road_lane
		
		if road_lane.type == 4:
			bike_on_road += 1
		
		number_of_lanes += 1
	
	var road_lane: RoadLane = road_lanes[road_lanes.size() - 1]
	var lane_end = road_lane.offset + road_lane.width / 2.0
	# Insert end points
	points.append(Vector2(lane_end, height))
	points.append(Vector2(lane_end, 0.0))
	
	# Insert point below first point as last point
	points.append(Vector2(points[0].x, 0.0))
	
	left_width = abs(points[0].x)
	right_width = abs(points[points.size() - 3].x)
	width = left_width + right_width
	
	$CSGPolygon3D.polygon = points
	
	# Set number of lanes in Shader
	$CSGPolygon3D.material.set_shader_parameter("number_of_lanes", number_of_lanes)
	$CSGPolygon3D.material.set_shader_parameter("lane_types", lane_types)
	$CSGPolygon3D.material.set_shader_parameter("lane_widths", lane_widths)
	$CSGPolygon3D.material.set_shader_parameter("road_length", length)
	
	$CSGPolygon3D.material.set_shader_parameter("left_bike_on_road", left_bike_on_road)
	$CSGPolygon3D.material.set_shader_parameter("right_bike_on_road", right_bike_on_road)
	


func custom_compare(a, b):
	return a.offset < b.offset


func get_left_width(intersection_id) -> float:
	return left_width if intersection_id == from_intersection else right_width


func get_right_width(intersection_id) -> float:
	return right_width if intersection_id == from_intersection else left_width


func get_info() -> Dictionary:
	return {
		"ID": id,
		"Name": road_name,
		"From Intersection": from_intersection,
		"To Intersection": to_intersection,
		"Width": width,
		"Length": length,
		"Speed Forward": speed_forward,
		"Speed Backwards": speed_backwards,
		"Lanes Forward": lanes_forward,
		"Lanes Backwards": lanes_backwards,
		"Direction": direction,
		"Type": type_to_names[type] if type_to_names.has(type) else "Unknown Type",
		"Physical Type": physical_type_to_names[physical_type] \
		if physical_type_to_names.has(physical_type) \
		else "Unknown Physical Type",
		"Bike on road": bike_on_road
	}
