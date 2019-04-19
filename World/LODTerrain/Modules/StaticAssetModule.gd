extends Module

var asset_result
var dscn_node = preload("res://addons/dscn_io/DSCN_Runtime_Node.gd")

export(int) var asset_id


func _ready() -> void:
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_building_data_from_server", []))


func _on_ready():
	for obj in asset_result:
		var name_path = obj.asset + ".dae.dscn"
		var dscn_node = dscn_node.new()
		
		# TODO: Instantiate


func get_building_data_from_server(d):
	var tile_pos = tile.get_true_position()
	var osm_z = tile.get_osm_zoom()
	
	asset_result = ServerConnection.get_json("/assetpos/get/%d/%d/%d/%d.json" % [asset_id, -tile_pos[0], tile_pos[2], osm_z])
	
	make_ready()

