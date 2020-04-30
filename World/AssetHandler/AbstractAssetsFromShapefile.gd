extends Spatial
class_name AbstractAssetsFromShapefile

#
# Abstract class for loading assets from shapefile points.
# The actual asset loading logic, based on the GeoPoint and its attributes,
# has to be implemented.
#

export(String) var shapefile_name  # Name of the shapefile in geodata.json

var radius = 5000
var max_assets = 100

var load_thread: Thread = Thread.new()
var previous_load_center_pos = [0, 0, 0]

var terrain_node: Spatial


func _get_points():
	var center_pos = terrain_node.get_center_position()
	return Geodot.get_points_near_position(GeodataPaths.get_absolute_with_ending(shapefile_name), -center_pos[0], center_pos[2], radius, max_assets)


func _process(delta: float) -> void:
	if terrain_node:
		var center_pos = terrain_node.get_center_position()
		
		# If the player has moved by a quarter of the radius since last update,
		#  do a new update
		if abs(center_pos[0] - previous_load_center_pos[0]) > radius / 4 \
				or abs(center_pos[2] - previous_load_center_pos[2]) > radius / 4 \
				and not load_thread.is_active():
			
			previous_load_center_pos = center_pos
			load_thread.start(self, "_reload_assets")


func _reload_assets(data):
	var points = _get_points()
	var root = Spatial.new()
	
	for point in points:
		var new_child = _create_asset_for_geopoint(point)
		
		if new_child:
			root.add_child(new_child)
	
	call_deferred("_done_loading")
	return root


# To be implemented by the specific handler.
func _create_asset_for_geopoint(geopoint):
	pass


func _done_loading():
	var root = load_thread.wait_to_finish()
	root.name = "AssetRoot"
	
	if has_node("AssetRoot"):
		get_node("AssetRoot").free()
	
	add_child(root)
