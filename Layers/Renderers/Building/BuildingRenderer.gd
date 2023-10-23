extends FeatureLayerCompositionRenderer


var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var plain_walls_scene = preload("res://Buildings/Components/PlainWalls.tscn")
var flat_roof_scene = preload("res://Buildings/Components/FlatRoof.tscn")
var pointed_roof_scene = preload("res://Buildings/Components/PointedRoof.tscn")

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height
var fallback_height = 10
var cellar_height = floor_height # For preventing partially floating buildings checked uneven surfaces

@onready var height_attribute = layer_composition.render_info.height_attribute_name


func _ready():
	super._ready()


func load_feature_instance(feature):
	var polygon = feature.get_outer_vertices()
	var holes = feature.get_holes()

	var building = building_base_scene.instantiate()

	# Load the components based checked the building attributes
	var height = util.str_to_var_or_default(
		feature.get_attribute(height_attribute), fallback_height)

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

		if util.str_to_var_or_default(slope, 35) > 15:
			roof = pointed_roof_scene.instantiate()
			var height_stdev = util.str_to_var_or_default(feature.get_attribute(
				layer_composition.render_info.height_stdev_attribute_name), 10)
			roof.set_height(fmod(height, floor_height) + height_stdev)

		if roof == null or not roof.can_build(polygon):
			roof = flat_roof_scene.instantiate()

		var color = Color(
			util.str_to_var_or_default(
				feature.get_attribute(layer_composition.render_info.red_attribute_name), 200) / 255.0,
			util.str_to_var_or_default(
				feature.get_attribute(layer_composition.render_info.green_attribute_name), 130) / 255.0,
			util.str_to_var_or_default(
				feature.get_attribute(layer_composition.render_info.blue_attribute_name), 130) / 255.0
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


func get_debug_info() -> String:
	return "{0} of maximally {1} polygons loaded.".format([
		str(get_child_count()),
		str(max_features)
	])
