extends LayerRenderer


var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var plain_walls_scene = preload("res://Buildings/Components/PlainWalls.tscn")
var flat_roof_scene = preload("res://Buildings/Components/FlatRoof.tscn")
var pointed_roof_scene = preload("res://Buildings/Components/PointedRoof.tscn")

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height
var fallback_height = 10
var cellar_height = floor_height # For preventing partially floating buildings on uneven surfaces

var building_instances = []

# The load radius corresponds to the vegetation extent in order to have a clean LOD border where both plants and buildings end.
var load_radius = Vegetation.get_max_extent()
var max_features = 2000


# Called when the node enters the scene tree for the first time.
func load_new_data():
	# Extract features
	var features = layer.get_features_near_position(center[0], center[1], load_radius, max_features)
	var height_attribute_name = layer.render_info.height_attribute_name
	
	# Create the buildings
	for feature in features:
		var polygon = feature.get_outer_vertices()
		var holes = feature.get_holes()
		
		var building = building_base_scene.instance()
		
		# Load the components based on the building attributes
		var height = int(feature.get_attribute(height_attribute_name)) \
						if height_attribute_name else fallback_height
		
		var num_floors = max(1, height / floor_height)
		
		# Add a cellar
		building.add_child(plain_walls_scene.instance())
		
		# Random facade texture
		var random_gen = RandomNumberGenerator.new()
		random_gen.seed = hash(polygon)
		
		var wall_texture
		var random = random_gen.randi_range(0, 10)
		
		if random >= 0 and random <= 5:
			wall_texture = preload("res://Resources/Textures/Buildings/facade/plaster_yellow.jpg")
		elif random > 5 and random <= 8:
			wall_texture = preload("res://Resources/Textures/Buildings/facade/plaster_white.jpg")
		elif random == 9:
			wall_texture = preload("res://Resources/Textures/Buildings/facade/plaster_green.jpg")
		elif random == 10:
			wall_texture = preload("res://Resources/Textures/Buildings/facade/plaster_blue.jpg")
		
		# Add the floors
		for i in range(num_floors):
			var walls = plain_walls_scene.instance()
			building.add_child(walls)
			
			walls.set_texture(wall_texture)
			walls.set_normalmap(preload("res://Resources/Textures/Buildings/facade/normalmap_plaster.jpg"))
		
		# Add the roof
		if layer.render_info is Layer.PolygonRenderInfo:
			var slope = feature.get_attribute(layer.render_info.slope_attribute_name)
			var roof
			
			if float(slope) > 15:
				roof = pointed_roof_scene.instance()
				roof.set_texture(preload("res://Resources/Textures/Buildings/roof/roof_white.jpg"))
				roof.set_normalmap(preload("res://Resources/Textures/Buildings/roof_normal/roof_3-normal.jpg"))
				
				var height_stdev = float(feature.get_attribute(layer.render_info.height_stdev_attribute_name))
				roof.set_height(fmod(height, floor_height) + height_stdev)
			
			if not roof or not roof.can_build(polygon):
				roof = flat_roof_scene.instance()
				roof.set_texture(preload("res://Resources/Textures/Buildings/roof/flat_roof_white.jpg"))
			
			var color = Color(
					float(feature.get_attribute(layer.render_info.red_attribute_name)) / 255.0,
					float(feature.get_attribute(layer.render_info.green_attribute_name)) / 255.0,
					float(feature.get_attribute(layer.render_info.blue_attribute_name)) / 255.0
			)
			
			roof.set_color(color)
			
			building.add_child(roof)
		
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
		) - cellar_height


func get_debug_info() -> String:
	return "{0} of maximally {1} polygons loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
