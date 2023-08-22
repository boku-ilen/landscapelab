extends Node3D
class_name RoadInstance

# The road object itself. Contains mostly data and keeps track of different lanes
# The car-road itself is also treated as a lane!

var road_curve: Curve3D

# Road Information
var id: int = 0
var road_name: String = "None"
var road_subname: String = "None"
var from_intersection: int = 0
var to_intersection: int = 0
var width: float = 0.0
var length: float = 0.0

var _road_lane_car_scene = preload("res://Layers/Renderers/Path/Roads/RoadLanes/RoadLaneCar.tscn")
var _road_lane_bike_scene = preload("res://Layers/Renderers/Path/Roads/RoadLanes/RoadLaneBike.tscn")
var _road_lane_pedestrian_scene = preload("res://Layers/Renderers/Path/Roads/RoadLanes/RoadLanePedestrian.tscn")
var _road_lane_parking_scene = preload("res://Layers/Renderers/Path/Roads/RoadLanes/RoadLaneParking.tscn")
var _road_lane_rail_scene = preload("res://Layers/Renderers/Path/Roads/RoadLanes/RoadLaneRail.tscn")

var road_lanes: Array = []


func load_from_feature(road_feature) -> void:
	for lane in road_lanes:
		lane.queue_free()
	
	road_lanes.clear()
	
	width = float(road_feature.get_attribute("width"))
	length = float(road_feature.get_attribute("length"))
	road_name = road_feature.get_attribute("road_name")
	road_subname = road_feature.get_attribute("road_subname")
	from_intersection = int(road_feature.get_attribute("from_intersection"))
	to_intersection = int(road_feature.get_attribute("to_intersection"))
	var lane_uses = road_feature.get_attribute("lane_uses")
	var lanes: PackedStringArray = lane_uses.split(';', false)
	
	for lane in lanes:
		var lane_infos: PackedStringArray = lane.split(',', false)
		var road_lane
		
		# Lane type specific info
		var lane_type = int(lane_infos[0])
		
		match lane_type:
			0: # Car
				road_lane = _road_lane_car_scene.instantiate()
				road_lane.speed_forward = road_feature.get_attribute("speed_forward")
				road_lane.speed_backwards = road_feature.get_attribute("speed_backwards")
				road_lane.lanes_forward = road_feature.get_attribute("lanes_forward")
				road_lane.lanes_backwards = road_feature.get_attribute("lanes_backwards")
				road_lane.base_type = road_feature.get_attribute("type")
				road_lane.physical_type = road_feature.get_attribute("physical_type")
			1: # Bike
				road_lane = _road_lane_bike_scene.instantiate()
			2: # Pedestrian
				road_lane = _road_lane_pedestrian_scene.instantiate()
			3: # Parking
				road_lane = _road_lane_parking_scene.instantiate()
			4: # Multipurpose
				road_lane = _road_lane_pedestrian_scene.instantiate()
			5: # Rails
				road_lane = _road_lane_rail_scene.instantiate()
		
		# General road lane info
		if road_lane:
			road_lane.lane_type = lane_type
			road_lane.road_curve = road_curve
			road_lane.road_width = float(lane_infos[1])
			road_lane.road_offset = float(lane_infos[2])
			road_lane.percentage_from = float(lane_infos[3])
			road_lane.percentage_to = float(lane_infos[4])
			
			road_lane.road_instance = self
			
			road_lanes.append(road_lane)
			self.add_child(road_lane)


func update_road_lanes() -> void:
	for road_lane in road_lanes:
		road_lane.update_road_lane()


func get_info() -> Array:
	return [
		RoadInfoData.new("ID", id, "", false),
		RoadInfoData.new("Name", road_name, "", false),
		RoadInfoData.new("Subname", road_subname, "", false),
		RoadInfoData.new("From Intersection", from_intersection, "", false),
		RoadInfoData.new("To Intersection", to_intersection, "", false),
		RoadInfoData.new("Width", width, "", false),
		RoadInfoData.new("Length", length, "", false),
	]
