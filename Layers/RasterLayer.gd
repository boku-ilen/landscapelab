extends Layer
class_name RasterLayer

# is of type Geodot.GeoRasterLayer
# TODO: look up how to access classes from gdnative for typing
var geo_raster_layer


func get_image(top_left_x: float, top_left_y: float, size_meters: float, img_size: int, interpolation_type: int):
	return geo_raster_layer.get_image(top_left_x, top_left_y, size_meters, img_size, interpolation_type)


func get_value_at_position(x: float, y: float):
	return geo_raster_layer.get_value_at_position(x, y)


func clone():
	var cloned_layer = duplicate()
	cloned_layer.geo_raster_layer = geo_raster_layer.clone()
	
	return cloned_layer
