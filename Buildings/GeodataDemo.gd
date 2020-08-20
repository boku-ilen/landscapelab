extends Spatial


#
# Demo for creating simple buildings from geodata.
# Polygon features near a given position are loaded. Each polygon is turned into a blocky building.
# The number of floors is decided based on the height attribute of the building.
#


export(String) var geodata_path
export(String) var building_layer_name
export(String) var height_attribute_name


var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var plain_walls_scene = preload("res://Buildings/Components/PlainWalls.tscn")
var flat_roof_scene = preload("res://Buildings/Components/FlatRoof.tscn")

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height


# Called when the node enters the scene tree for the first time.
func _ready():
	# Load the geodata
	var dataset = Geodot.get_dataset(geodata_path)
	var layer = dataset.get_feature_layer(building_layer_name)
	
	# Extract features
	var features = layer.get_features_near_position(1577309.91, 5960304.19, 2000, 1000)
	
	var time_before = OS.get_ticks_usec()
	
	# Create the buildings
	for feature in features:
		var polygon = feature.get_outer_vertices()
		var holes = feature.get_holes()
		
		var building = building_base_scene.instance()
		
		# Load the components based on the building attributes
		var height = int(feature.get_attribute(height_attribute_name))
		var num_floors = max(1, height / floor_height)
		
		# Add the floors
		for i in range(num_floors):
			building.add_child(plain_walls_scene.instance())
		
		# Add the roof
		building.add_child(flat_roof_scene.instance())
		
		# Set parameters in the building base
		building.set_footprint(polygon)
		building.set_holes(holes)
		building.set_offset(1577309, 5960304)
		
		# Build!
		building.build()
		
		add_child(building)
	
	var time_after = OS.get_ticks_usec()
	
	print("Creating " + str(features.size()) + " buildings took " + str((time_after - time_before) * 0.000001) + " seconds")
