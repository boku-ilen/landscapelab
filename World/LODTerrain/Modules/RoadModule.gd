extends Module

#
# Implementation of an Asset Handler for linear assets such as streets.
#


export(PackedScene) var linear_drawer
export(int) var line_type


func init():
	var roads = _get_server_result()
	
	if roads:
		for id in roads:
			_spawn_asset(roads, id)
	else:
		logger.warning("Coulnd't get roads!")
	
	_done_loading()


# Abstract function which returns the result (a list of assets) of the specific request being implemented.
func _get_server_result():
	return tile.get_texture_result("linear/tile/%d" % [line_type])


# Abstract function which instances the asset with the given asset_id.
func _spawn_asset(result, instance_id):
	var line = result[instance_id]["line"]
	var width = result[instance_id]["width"]
	
	var vectored_line = _vectorize_points(line)
		
	var drawer = linear_drawer.instance()
	
	drawer.name = String(instance_id)
	
	drawer.set_width(width)
	drawer.add_points(vectored_line)
	
	get_node("TransformReset").add_child(drawer)
	
	return true


func _server_point_to_engine_pos(server_x, server_y):
	# Convert the 2D world position received from the server to in-engine 2D coordinates
	var instance_pos_2d = Offset.to_engine_coordinates([-server_x, server_y])
	
	# Return as 3D position
	return Vector3(instance_pos_2d.x, 0, instance_pos_2d.y)


# Takes a list of 2-dimensional WebMercator points from the server response and turns them into in-engine 3D points.
func _vectorize_points(line_array):
	var vectored_line = []
	
	for point in line_array:
		# These positions are relative to the point approximately in the middle of the road (the middle_point)
		vectored_line.append(_server_point_to_engine_pos(point[0], point[1]))
	
	return vectored_line
