extends Object
class_name ScatteredLocationsGetter


var center_x
var center_y
var size
var density
var randomness
var scatter_layer
var height_layer
var condition

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
