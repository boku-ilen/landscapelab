extends LayerCompositionRenderer


var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var plain_walls_scene = preload("res://Buildings/Components/PlainWalls.tscn")
var flat_roof_scene = preload("res://Buildings/Components/FlatRoof.tscn")
var pointed_roof_scene = preload("res://Buildings/Components/PointedRoof.tscn")

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height
var fallback_height = 10
var cellar_height = floor_height # For preventing partially floating buildings checked uneven surfaces

var building_instances = {}

# The load radius corresponds to the vegetation extent in order to have a clean LOD border where both plants and buildings end.
var load_radius = Vegetation.get_max_extent()
var max_features = 2000


func is_new_loading_required(position_diff: Vector3) -> bool:
	if Vector2(position_diff.x, position_diff.z).length_squared() >= pow(load_radius / 4.0, 2):
		return true
	
	return false


# Called when the node enters the scene tree for the first time.
func full_load():
	# Extract features
	var features = layer_composition.render_info.geo_feature_layer.get_features_near_position(float(center[0]), float(center[1]), float(load_radius), max_features)
	var height_attribute_name = layer_composition.render_info.height_attribute_name
	
	# Create the buildings
	for feature in features:
		building_instances[str(feature.get_id())] = create_building(feature, height_attribute_name)


func adapt_load(_diff: Vector3):
	var features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
				float(center[0]) + position_manager.center_node.position.x,
				float(center[1]) - position_manager.center_node.position.z,
				float(load_radius), max_features
	)
	var height_attribute_name = layer_composition.render_info.height_attribute_name
	
	for feature in features:
		var fid = str(feature.get_id())
		building_instances[fid] = create_building(feature, height_attribute_name) \
				if not has_node(fid) else true
	
	call_deferred("apply_new_data")


func create_building(feature, height_attribute_name):
	var polygon = feature.get_outer_vertices()
	var holes = feature.get_holes()
	
	var building = building_base_scene.instantiate()
	
	# Load the components based checked the building attributes
	var height = str_to_var(feature.get_attribute(height_attribute_name)) \
					if height_attribute_name else fallback_height
	
	var num_floors = max(1, height / floor_height)
	
	# Add a cellar
	var cellar = plain_walls_scene.instantiate()
	cellar.set_color(Color.LIGHT_GRAY)
	building.add_child(cellar)
	
	# FIXME: Find a way not to have a half window texture here
#		# In order to get a more accurate height, we add a building base if there's a remainder of
#		# half a floor height; this also adds some variation and is probably realistic in many cases
#		if fmod(height, floor_height) > floor_height / 2.0:
#			var base_floor = plain_walls_scene.instantiate()
#			base_floor.height = floor_height / 2.0
#			base_floor.set_window_shading(false)
#			base_floor.set_color(Color.GRAY)
#			building.add_child(base_floor)
	
	# Random facade texture
	var random_gen = RandomNumberGenerator.new()
	random_gen.seed = hash(polygon)
	
	var wall_color = Color.WHITE_SMOKE
	var random = random_gen.randi_range(0, 10)
	
	if random >= 0 and random <= 5:
		wall_color = Color.LIGHT_YELLOW
	elif random > 5 and random <= 8:
		wall_color = Color.WHITE_SMOKE
	elif random == 9:
		wall_color = Color.DARK_SEA_GREEN
	elif random == 10:
		wall_color = Color.LIGHT_BLUE
	
	# Add the floors
	for i in range(num_floors):
		var walls = plain_walls_scene.instantiate()
		building.add_child(walls)
		
		walls.set_color(wall_color)
	
	# Add the roof
	if layer_composition.render_info is LayerComposition.BuildingRenderInfo:
		var slope = feature.get_attribute(layer_composition.render_info.slope_attribute_name)
		var roof = null
		
		if str_to_var(slope) > 15:
			roof = pointed_roof_scene.instantiate()
			var height_stdev = str_to_var(feature.get_attribute(layer_composition.render_info.height_stdev_attribute_name))
			roof.set_height(fmod(height, floor_height) + height_stdev)
		
		if roof == null or not roof.can_build(polygon):
			roof = flat_roof_scene.instantiate()
		
		var color = Color(
				str_to_var(feature.get_attribute(layer_composition.render_info.red_attribute_name)) / 255.0,
				str_to_var(feature.get_attribute(layer_composition.render_info.green_attribute_name)) / 255.0,
				str_to_var(feature.get_attribute(layer_composition.render_info.blue_attribute_name)) / 255.0
		)
		
		# Increase contrast and saturation
		color.v *= 0.9
		color.s *= 1.6
		
		roof.set_color(color)
		
		building.add_child(roof)
	
	# Set parameters in the building base
	building.set_footprint(polygon)
	building.set_holes(holes)
	building.set_offset(center[0], center[1])
	
	building.name = str(feature.get_id())
	
	# Build!
	building.build()
	
	building.position.y = layer_composition.render_info.ground_height_layer.get_value_at_position(
			building.get_center().x + center[0],
			-building.get_center().z + center[1]
		) - cellar_height
	
	return building


func apply_new_data():
	for child in get_children():
		if not building_instances.has(child.name):
			child.queue_free()
	
	for building_id in building_instances.keys():
		if not has_node(building_id):
			add_child(building_instances[building_id])
	
	building_instances.clear()
	
	_apply_daytime_change(is_daytime)
	
	logger.info("Applied new BuildingRenderer data for %s" % [name], LOG_MODULE)


func _ready():
	super._ready()


func set_heights():
	var height_layer = layer_composition.render_info.ground_height_layer
	
	for building in get_children():
		# Move the building down by the cellar_height so that their ground floor ends up at the
		#  terrain height
		building.position.y = height_layer.get_value_at_position(
			building.get_center().x + center[0],
			-building.get_center().z + center[1]
		) - cellar_height


func get_debug_info() -> String:
	return "{0} of maximally {1} polygons loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
