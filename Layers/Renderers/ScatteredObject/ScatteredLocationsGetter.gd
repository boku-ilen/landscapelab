extends Object
class_name ScatteredLocationsGetter


# Map-space coordinates of the center of this chunk
var center_x: int
var center_y: int

# Size of the chunk (length of the rectangle's sides), in meters
var size: float

# How many objects should be placed per meter
# For example, 0.5 would place one object every 2 meters
var density: float

# How much we should randomly deviate from a coordinate-aligned grid
# 0.0 means no deviation (perfect grid), 1.0 means full random deviation
var randomness: float

# Layer containing the values to compare against with the `condition`
var scatter_layer: GeoRasterLayer

# Layer containing the y-coordinate-values for the placed objects
var height_layer: GeoRasterLayer

# Condition which the `scatter_layer` must fulfill in order for an object to be placed there.
# * matches zero or more arbitrary characters.
# ? matches any single character except a period.
var condition: String

# Own RNG in order to get deterministic results each time the chunk is loaded
var rng = RandomNumberGenerator.new()


func _init(new_center_x, new_center_y, new_size, new_density, new_randomness, new_scatter_layer, new_height_layer, new_condition):
	center_x = new_center_x
	center_y = new_center_y
	size = new_size
	density = new_density
	randomness = new_randomness
	scatter_layer = new_scatter_layer
	height_layer = new_height_layer
	condition = new_condition
	
	rng.seed = new_center_x + new_center_y


# TODO: Make the random locations deterministic by using a custom RNG object

# TODO: Add better sample distribution and variable density using blue noise:
# https://www.vertexfragment.com/ramblings/variable-density-poisson-sampler/

func get_object_locations():
	var object_locations = []
	
	var resolution = int(size * density * 2.0)
	
	var top_left_x = float(center_x - size / 2)
	var top_left_y = float(center_y + size / 2)
	
	var validation_image = scatter_layer.get_image(
		top_left_x,
		top_left_y,
		size,
		resolution,
		0
	).get_image()
	
	for x in range(0, size, 1.0 / density):
		for y in range(0, size, 1.0 / density):
			var candidate = Vector3(
				x + (1.0 / density) * rng.randf_range(-0.5, 0.5) * randomness,
				0.0,
				y + (1.0 / density) * rng.randf_range(-0.5, 0.5) * randomness
			)
			
			var value_here = validation_image.get_pixel(
				candidate.x * density * 2.0,
				candidate.z * density * 2.0
			).r
			
			var value_here_stringed = str(int(value_here))
			
			if value_here_stringed.match(condition):
				candidate.x -= size / 2
				candidate.z -= size / 2 
				candidate.y = height_layer.get_value_at_position(candidate.x + center_x, center_y - candidate.z)
				object_locations.append(candidate)
	
	return object_locations
