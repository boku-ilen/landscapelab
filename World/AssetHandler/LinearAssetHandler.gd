extends "res://World/AssetHandler/AbstractAssetHandler.gd"

#
# Implementation of an Asset Handler for linear assets such as streets.
#


export(PackedScene) var linear_drawer
export(int) var line_type


# Abstract function which returns the result (a list of assets) of the specific request being implemented.
func _get_server_result():
	var player_pos = PlayerInfo.get_true_player_position()
	return ServerConnection.get_json("/linear/%d.0/%d.0/%d.json" % [-player_pos[0], player_pos[2], line_type], false)


# Abstract function which instances the asset with the given asset_id.
func _spawn_asset(instance_id):
	var line = _result[instance_id]["line"]
	var vectored_line = []
	
	for point in line:
		vectored_line.append(_server_point_to_engine_pos(point[0], point[1]))
		
	var drawer = linear_drawer.instance()
	drawer.name = String(instance_id)
	add_child(drawer)
	
	drawer.add_points(vectored_line)
