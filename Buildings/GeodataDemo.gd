extends Node3D


#
# Demo for creating simple buildings from geodata.
# Polygon features near a given position are loaded. Each polygon is turned into a blocky building.
# The number of floors is decided based checked the height attribute of the building.
#


@export var geodata_path: String
@export var building_layer_name: String
@export var height_attribute_name: String


var building_base_scene = preload("res://Buildings/BuildingBase.tscn")
var plain_walls_scene = preload("res://Buildings/Components/PlainWalls.tscn")
var flat_roof_scene = preload("res://Buildings/Components/PointedRoof.tscn")

var floor_height = 2.5 # Height of one building floor for calculating the number of floors from the height


# Called when the node enters the scene tree for the first time.
func _ready():
	# Load the geodata
	var dataset = Geodot.get_dataset(geodata_path)
	var layer = dataset.get_feature_layer(building_layer_name)
	
	# Extract features
	var features = layer.get_features_near_position(662456.130, 455465.165, 200, 100)
	
	var time_before = Time.get_ticks_usec()
	
	# Create the buildings
	for feature in features:
		var polygon = feature.get_outer_vertices()
		var holes = feature.get_holes()
		
		var building = building_base_scene.instantiate()
		
		# Load the components based checked the building attributes
		var height = int(feature.get_attribute(height_attribute_name))
		var num_floors = max(1, height / floor_height)
		
		# Add the floors
		for i in range(num_floors):
			building.add_child(plain_walls_scene.instantiate())
		
		# Add the roof
		var flat_roof = flat_roof_scene.instantiate()
		flat_roof.set_texture(preload("res://Resources/Textures/Buildings/roof/roof_2-diffuse.jpg"))
		building.add_child(flat_roof)
		
		# Set parameters in the building base
		building.set_footprint(polygon)
		building.set_holes(holes)
		building.set_offset(662456, 455465)
		
		# Build!
		building.build()
		
		add_child(building)
	
	var time_after = Time.get_ticks_usec()
	
	print("Creating " + str(features.size()) + " buildings took " + str((time_after - time_before) * 0.000001) + " seconds")
