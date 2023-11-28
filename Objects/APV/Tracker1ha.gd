extends Node3D


var time_manager: TimeManager :
	get:
		return time_manager
	set(new_time_manager):
		time_manager = new_time_manager
		for child in get_children():
			child.time_manager = time_manager

var feature: GeoPoint
var height_layer: GeoRasterLayer :
	set(new_height_layer):
		height_layer = new_height_layer
		var starting_height = height_layer.get_value_at_position(
			feature.get_vector3().x,
			-feature.get_vector3().z)
		for child in get_children():
			var child_geo_pos = feature.get_vector3() + child.position
			child.position.y =  height_layer.get_value_at_position(
				child_geo_pos.x,
				-child_geo_pos.z) - starting_height
