extends RoadLane
class_name RoadLanePedestrian


@export var lid = 2002



func update_road_lane() -> void:
	super.update_road_lane()
	$RoadLanePolygon.material.set_shader_parameter("lid_color", Color8(
		lid % 255,
		floor(lid / 255),
		0
	))


func reset_custom_values() -> void:
	super.reset_custom_values()


func get_info() -> Array:
	var info = super.get_info()
	info.append_array([])
	return info
