extends Module

var spawn_buildings = false
var buildings = []

func _ready() -> void:
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_building_data_from_server", []))
	
func _process(delta: float) -> void:
	if spawn_buildings:
		for b in buildings:
			add_child(b)
		
		done_loading()
		spawn_buildings = false

func get_building_data_from_server(d):
	var tile_pos = tile.get_true_position()
	var osm_z = tile.get_osm_zoom()
	
	var result = ServerConnection.getJson("/assetpos/get/1/%d/%d/%d.json" % [-tile_pos[0], tile_pos[2], osm_z])
	
	for obj in result:
		# TODO: Instantiate buildings here
		var ins = MeshInstance.new()
		
		buildings.append(ins)
	
	spawn_buildings = true