extends RoadLane
class_name RoadLaneBike


func update_road_lane() -> void:
	super.update_road_lane()


func reset_custom_values() -> void:
	super.reset_custom_values()


func get_info() -> Array:
	var info = super.get_info()
	info.append_array([])
	return info
