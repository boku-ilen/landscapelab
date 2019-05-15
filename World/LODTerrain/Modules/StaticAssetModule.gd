extends Module

#
# This module instantiates static assets by getting their information from the server
# and loading and placing them at the desired position.
# Static assets are assets which are spawned at a certain position and stay there, with
# no interaction with the client other than perhaps collisions. As opposed to other assets,
# they are not known to the client before, and instead loaded from DSCN files.
#

var asset_result
var dscn_node = preload("res://addons/dscn_io/DSCN_Runtime_Node.gd")

export(int) var asset_type_id


func _ready() -> void:
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_asset_data_from_server", []))


func _on_ready():
	if asset_result:
		for obj in asset_result:
			# TODO: We only get the names, so we'll need to build the full path here somehow
			var name_path = "/path/to/asset/" + obj.asset + ".dae.dscn"
			var dscn_node = dscn_node.new()
			
			# TODO: Untested! Variable names and formats in the 'obj' might not be correct
			var abs_pos = obj.position
			var local_pos = Offset.to_engine_coordinates(abs_pos)
			var ground_pos = WorldPosition.get_position_on_ground(Vector3(local_pos.x, 0, local_pos.y))
			
			dscn_node.transform.origin = ground_pos
			
			# Load the scene
			dscn_node.filepath = name_path
			dscn_node.import_dscn()
			
			add_child(dscn_node)


func get_asset_data_from_server(d):
	asset_result = tile.get_texture_result("assetpos/get_all/%d" % [asset_type_id])
	
	make_ready()
