extends RoadLane
class_name RoadLaneBike


func update_road_lane() -> void:
	super.update_road_lane()

func get_info() -> Dictionary:
	var info = super.get_info()
	info.merge({})
	return info
