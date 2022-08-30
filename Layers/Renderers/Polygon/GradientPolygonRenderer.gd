extends LayerRenderer


var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var plain_walls_scene = preload("res://Buildings/Components/PlainWalls.tscn")

var building_instances = []

# The load radius corresponds to the vegetation extent in order to have a clean LOD border where both plants and buildings end.
var load_radius = 20000
var max_features = 2000


# Called when the node enters the scene tree for the first time.
func load_new_data():
	# Extract features
	var features = layer.get_features_near_position(center[0], center[1], load_radius, max_features)

	# Create the buildings
	for feature in features:
		var polygon = feature.get_outer_vertices()
		var holes = feature.get_holes()
		
		var building = building_base_scene.instance()
		
		var num_floors = max(1, float(layer.render_info.polygon_height) / 2.5)
		
		for i in range(num_floors):
			var walls = plain_walls_scene.instance()
			walls.set_color(Color.greenyellow)
			building.add_child(walls)
		
		# Set parameters in the building base
		building.set_footprint(polygon)
		building.set_holes(holes)
		building.set_offset(center[0], center[1])
		
		# Build!
		building.build()
		
		building_instances.append(building)


func apply_new_data():
	for child in get_children():
		child.queue_free()
	
	for building in building_instances:
		add_child(building)
	
	building_instances.clear()
	set_heights()
	
	_apply_daytime_change(is_daytime)


func set_heights():
	var height_layer = layer.render_info.ground_height_layer
	
	for building in get_children():
		# Move the building down by the cellar_height so that their ground floor ends up at the
		#  terrain height
		building.translation.y = height_layer.get_value_at_position(
			building.get_center().x + center[0],
			-building.get_center().z + center[1]
		)


func get_debug_info() -> String:
	return "{0} of maximally {1} polygons loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
