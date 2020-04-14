extends Spatial


#
# 
#


export(PackedScene) var asset_scene
export(String) var shapefile_path

var radius = 5000
var max_assets = 100

var load_thread: Thread = Thread.new()
var previous_load_player_pos = [0, 0, 0]


func _get_points():
	var player_pos = PlayerInfo.get_true_player_position()
	return Geodot.get_points_near_position(shapefile_path, -player_pos[0], player_pos[2], radius, max_assets)


func _process(delta: float) -> void:
	var player_pos = PlayerInfo.get_true_player_position()
	
	if abs(player_pos[0] - previous_load_player_pos[0]) > 100.0 \
			or abs(player_pos[2] - previous_load_player_pos[2]) > 100.0 \
			and not load_thread.is_active():
			
		print("Loading")
		previous_load_player_pos = player_pos
		load_thread.start(self, "_reload_assets")


func _reload_assets(data):
	var points = _get_points()
	var root = Spatial.new()
	
	for point in points:
		root.add_child(_create_asset_at_position(point.get_offset_vector3(Offset.x, 0, -Offset.z)))
	
	call_deferred("_done_loading")
	return root


func _create_asset_at_position(position: Vector3):
	var asset = asset_scene.instance()
	asset.transform.origin = position
	
	return asset


func _done_loading():
	var root = load_thread.wait_to_finish()
	root.name = "AssetRoot"
	
	if has_node("AssetRoot"):
		get_node("AssetRoot").free()
	
	add_child(root)
