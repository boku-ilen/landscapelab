extends CreationCondition
class_name GreaterThanRasterCreationCondition


var raster_layer
var greater_than_comparator


func _init(initial_name,initial_raster_layer,initial_greater_than_comparator):
	name = initial_name
	raster_layer = initial_raster_layer
	greater_than_comparator = initial_greater_than_comparator


func is_creation_allowed_at_position(position):
	var value_here = raster_layer.get_value_at_position(position.x, -position.z)
	return value_here > greater_than_comparator
