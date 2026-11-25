extends CreationCondition
class_name CalculatedRasterCreationCondition


var raster_layer
var calculation: String


func _init(initial_name, initial_raster_layer, initial_calculation):
	name = initial_name
	raster_layer = initial_raster_layer
	calculation = initial_calculation


func is_creation_allowed_at_position(position):
	return util.evaluate_formula(calculation,
		func(name): return str(raster_layer.get_value_at_position(position.x, -position.z))
	)
