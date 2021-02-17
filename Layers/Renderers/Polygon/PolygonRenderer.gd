extends LayerRenderer


var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var plain_walls_scene = preload("res://Buildings/Components/PlainWalls.tscn")
var flat_roof_scene = preload("res://Buildings/Components/FlatRoof.tscn")

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height
var fallback_height = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: Move this position out, pass it from the World node down to here
	var pos_x = 420776.711
	var pos_y = 453197.501
	
	# Extract features
	var features = layer.get_features_near_position(pos_x, pos_y, 1000, 1000)
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
		
		# Add the floors
		for i in range(num_floors):
			building.add_child(plain_walls_scene.instance())
		
		# Add the roof
		building.add_child(flat_roof_scene.instance())
		
		# Set parameters in the building base
		building.set_footprint(polygon)
		building.set_holes(holes)
		building.set_offset(pos_x, pos_y)
		
		# Build!
		building.build()
		
		add_child(building)
	
	set_heights()


func set_heights():
	var height_layer = layer.render_info.ground_height_layer
	
	for building in get_children():
		building.translation.y = height_layer.get_value_at_position(
			building.get_center().x + 420776.711,
			-building.get_center().z + 453197.501
		)
