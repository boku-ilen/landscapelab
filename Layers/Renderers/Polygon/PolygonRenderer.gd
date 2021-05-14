extends LayerRenderer


var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var plain_walls_scene = preload("res://Buildings/Components/PlainWalls.tscn")
var flat_roof_scene = preload("res://Buildings/Components/FlatRoof.tscn")

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height
var fallback_height = 10
var cellar_height = floor_height # For preventing partially floating buildings on uneven surfaces


# Called when the node enters the scene tree for the first time.
func load_new_data():
	# Extract features
	var features = layer.get_features_near_position(center[0], center[1], 1000, 1000)
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
		
		# Add the floors
		for i in range(num_floors):
			building.add_child(plain_walls_scene.instance())
		
		# Add the roof
		building.add_child(flat_roof_scene.instance())
		
		# Set parameters in the building base
		building.set_footprint(polygon)
		building.set_holes(holes)
		building.set_offset(center[0], center[1])
		
		# Build!
		building.build()
		
		add_child(building)
	
	set_heights()


func apply_new_data():
	# FIXME: Only add_childs here, not in load_new_data!
	pass


func set_heights():
	var height_layer = layer.render_info.ground_height_layer
	
	for building in get_children():
		# Move the building down by the cellar_height so that their ground floor ends up at the
		#  terrain height
		building.translation.y = height_layer.get_value_at_position(
			building.get_center().x + center[0],
			-building.get_center().z + center[1]
		) - cellar_height
