extends Layer
class_name RasterLayer

# is of type Geodot.GeoRasterLayer
# TODO: look up how to access classes from gdnative for typing
var geo_raster_layer


func get_min():
	return geo_raster_layer.get_min()


func get_max():
	return geo_raster_layer.get_max()


func get_image(top_left_x: float, top_left_y: float, size_meters: float, img_size: int, interpolation_type: int):
	return geo_raster_layer.get_image(top_left_x, top_left_y, size_meters, img_size, interpolation_type)


func get_value_at_position(x: float, y: float):
	return geo_raster_layer.get_value_at_position(x, y)


func get_extent():
	return geo_raster_layer.get_extent()


func get_center():
	return geo_raster_layer.get_center()


func clone():
	var cloned_layer = duplicate()
	cloned_layer.geo_raster_layer = geo_raster_layer.clone()
	
	return cloned_layer


func get_path():
	if geo_raster_layer.get_dataset() == null:
		return geo_raster_layer.get_name()
	return geo_raster_layer.get_dataset().get_path()


func get_name():
	if geo_raster_layer.get_dataset() == null:
		return geo_raster_layer.get_name().substr(geo_raster_layer.get_name().find_last("/"))
	return geo_raster_layer.get_name()
