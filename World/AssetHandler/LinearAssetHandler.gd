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
	return ServerConnection.get_json("/linear/%d.0/%d.0/%d.json" % [-player_pos[0], player_pos[2], line_type], false)


# Abstract function which instances the asset with the given asset_id.
func _spawn_asset(instance_id):
	var line = _result[instance_id]["line"]
	var vectored_line = _vectorize_points(line)
		
	var drawer = linear_drawer.instance()
	drawer.name = String(instance_id)
	add_child(drawer)
	
	drawer.add_points(vectored_line)


# Takes a list of 2-dimensional WebMercator points from the server response and turns them into in-engine 3D points.
func _vectorize_points(line_array):
	var vectored_line = []
	
	for point in line_array:
		vectored_line.append(_server_point_to_engine_pos(point[0], point[1]))
		
	_interpolate_points(vectored_line)
	
	return vectored_line


# Adds points between points which are more than maximum_distance_between_points from each other.
# Example situation where this is necessary: A very long and straight road which goes over a hill: We need
#  to add points so that the road goes neatly along the curve of the hill, instead of straight through it.
func _interpolate_points(line):
	# FIXME: This function is inefficient (many iterations and recursions) and not very clean (inserting
	#  into a list while iterating over it). It works, but should be improved!
	var done = true
	
	for point_id in range(0, line.size() - 1):
		# If this point is too far away from the next point, add one inbetween
		# The squared distance is used for efficiency. 1 is added to the minimum distance to prevent floating
		#  point errors from making this loop forever, since the minimum distance is never actually reached.
		if line[point_id].distance_squared_to(line[point_id + 1]) > pow(maximum_distance_between_points + 1, 2):
			# The direction is the vector from this point to the next one.
			var direction = (line[point_id + 1] - line[point_id]).normalized()
			var new_point = line[point_id] + direction * maximum_distance_between_points
			line.insert(point_id + 1, new_point)
			
			done = false
			
			# We're done for this recursion - we need to break here since we're inserting into a list which we're
			#  iterating over.
			break
	
	# If we inserted a point, there may be more that we need to insert. Recurse!
	if not done: _interpolate_points(line)
