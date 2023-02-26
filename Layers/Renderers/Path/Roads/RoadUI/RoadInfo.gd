extends Window
class_name RoadInfo

var road_info_tab_scene = preload("res://Layers/Renderers/Path/Roads/RoadUI/RoadInfoTab.tscn")


func _ready():
	self.close_requested.connect(self.hide)
	self.size_changed.connect(_size_changed)


func set_data(road_instance: RoadInstance) -> void:
	reset_data()
	var road_tab: RoadInfoTab = road_info_tab_scene.instantiate()
	road_tab.name = "Road"
	
	var road_info = road_instance.get_info()
	for property in road_info.keys():
		road_tab.add_property(property, road_info[property])
	
	$RoadInfoTabs.add_child(road_tab)
	
	var index = 1
	for road_lane in road_instance.road_lanes:
		var road_lane_tab: RoadInfoTab = road_info_tab_scene.instantiate()
		road_lane_tab.name = "Road Lane %s" %[index]
		
		var road_lane_info = road_lane.get_info()
		for property in road_lane_info.keys():
			road_lane_tab.add_property(property, road_lane_info[property])
		
		$RoadInfoTabs.add_child(road_lane_tab)
		index += 1


func reset_data() -> void:
	for tab in $RoadInfoTabs.get_children():
		tab.free()


func _size_changed() -> void:
	$RoadInfoTabs.size = Vector2(self.size)
