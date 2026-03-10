extends CreationCondition
class_name CalculatedRasterCreationCondition


var raster_layer
var calculation: String


func _init(initial_name, initial_raster_layer, initial_calculation):
	name = initial_name
	raster_layer = initial_raster_layer
	calculation = initial_calculation


func is_creation_allowed_at_position(position):
	var prepared_string = calculation.replace("$RASTER$", str(raster_layer.get_value_at_position(position.x, -position.z)))
	
	var expression = Expression.new()
	expression.parse(prepared_string)
	var result = expression.execute()
	
	return result
