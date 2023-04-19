extends Window
class_name RoadInfo

var road_lane_info_scene = preload("res://Layers/Renderers/Path/Roads/RoadUI/RoadLaneInfo.tscn")
var road_instance: RoadInstance

func _ready():
	self.close_requested.connect(self.hide)
	self.size_changed.connect(_size_changed)
	
	#$RoadLaneInfos/MarginContainer/ResetButton.pressed.connect(_reset_pressed)


func set_data(road_instance: RoadInstance) -> void:
	reset_data()
	self.road_instance = road_instance
	var road_lane_info: RoadLaneInfo = road_lane_info_scene.instantiate()
	road_lane_info.name = "Road"
	
	var road_info_datas = road_instance.get_info()
	for road_info_data in road_info_datas:
		road_lane_info.add_property(road_info_data)
	
	$RoadLaneInfos/Tabs.add_child(road_lane_info)
	
	var index = 1
	for road_lane in road_instance.road_lanes:
		road_lane_info = road_lane_info_scene.instantiate()
		road_lane_info.name = "Road Lane %s" %[index]
		
		road_info_datas = road_lane.get_info()
		for road_info_data in road_info_datas:
			road_lane_info.add_property(road_info_data)
		
		$RoadLaneInfos/Tabs.add_child(road_lane_info)
		index += 1


func reset_data() -> void:
	for tab in $RoadLaneInfos/Tabs.get_children():
		tab.free()


func _size_changed() -> void:
	$RoadLaneInfos.size = Vector2(self.size)


func _reset_pressed() -> void:
	$RoadLaneInfos/Tabs.get_current_tab_control().reset_custom_values()
