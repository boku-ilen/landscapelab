extends RoadLane
class_name RoadLanePedestrian


@export var lid = 2002
@export var lid_center = 7201



func update_road_lane() -> void:
	super.update_road_lane()
	$RoadLanePolygon.material.set_shader_parameter("lid_color", Color8(
		lid % 255,
		floor(lid / 255),
		0
	))
	$RoadLanePolygon.material.set_shader_parameter("lid_color_center", Color8(
		lid_center % 255,
		floor(lid_center / 255),
		0
	))


func reset_custom_values() -> void:
	super.reset_custom_values()


func get_info() -> Array:
	var info = super.get_info()
	info.append_array([])
	return info
