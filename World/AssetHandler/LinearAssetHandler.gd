extends "res://World/AssetHandler/AbstractAssetHandler.gd"

#
# Implementation of an Asset Handler for linear assets such as streets.
#


export(PackedScene) var linear_drawer
export(int) var line_type

var maximum_distance_between_points = Settings.get_setting("assets", "linear-max-distance")


func _ready():
	update_interval = Settings.get_setting("assets", "linear-update-interval")


# Abstract function which returns the result (a list of assets) of the specific request being implemented.
func _get_server_result():
	var player_pos = PlayerInfo.get_true_player_position()
	# FIXME: this should be handled by geodot in the future
	return ServerConnection.get_json("/linear/%d.0/%d.0/%d.json" % [-player_pos[0], player_pos[2], line_type], false)


# Abstract function which instances the asset with the given asset_id.
func _spawn_asset(instance_id):
	var line = _result[instance_id]["line"]
	var width = _result[instance_id]["width"]
	var middle_point_and_vectored_line = _vectorize_points(line)
	
	var middle_point = middle_point_and_vectored_line[0]
	var vectored_line = middle_point_and_vectored_line[1]
		
	var drawer = linear_drawer.instance()
	
	drawer.name = String(instance_id)
	
	add_child(drawer)
	
	# We want the global origin of the drawer to be approximately in the center of the road.
	# This is e.g. so that the tile which the GroundedSpatial is bound to is accurate.
	drawer.global_transform.origin = middle_point
	
	drawer.set_width(width)
	drawer.add_points(vectored_line)
	
	GlobalSignal.emit_signal("overlay_updated")
	
	return true


# Takes a list of 2-dimensional WebMercator points from the server response and turns them into in-engine 3D points.
func _vectorize_points(line_array):
	var vectored_line = []
	
	var middle_index = floor(line_array.size() / 2)
	var middle_point = _server_point_to_engine_pos(line_array[middle_index][0], line_array[middle_index][1])
	
	for point in line_array:
		# These positions are relative to the point approximately in the middle of the road (the middle_point)
		vectored_line.append(_server_point_to_engine_pos(point[0], point[1]) - middle_point)
	
	_interpolate_points(vectored_line)
	
	return [middle_point, vectored_line]


# Adds points between points which are more than maximum_distance_between_points from each other.
# Example situation where this is necessary: A very long and straight road which goes over a hill: We need
#  to add points so that the road goes neatly along the curve of the hill, instead of straight through it.
func _interpolate_points(line):
	var done = true
	
	var point_id = 0
	
	while true:
		# If this point has no next point, we're done
		if point_id > line.size() - 2:
			break
		
		# If the distance is too large, interpolate a point
		if line[point_id].distance_squared_to(line[point_id + 1]) > pow(maximum_distance_between_points + 1, 2):
			# The direction is the vector from this point to the next one.
			var direction = (line[point_id + 1] - line[point_id]).normalized()
			var new_point = line[point_id] + direction * maximum_distance_between_points
			
			line.insert(point_id + 1, new_point)
			
		point_id += 1
