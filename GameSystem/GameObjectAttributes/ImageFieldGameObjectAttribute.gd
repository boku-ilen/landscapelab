extends GameObjectAttribute
class_name ImageFieldGameObjectAttribute

# Calculates statistics for an image encoded as a binary field.


var image_attribute_name
var width_attribute_name
var height_attribute_name
var statistic


func _init(initial_name, initial_image_attribute_name, initial_width_attribute_name,
		initial_height_attribute_name, initial_statistic):
	name = initial_name
	image_attribute_name = initial_image_attribute_name
	width_attribute_name = initial_width_attribute_name
	height_attribute_name = initial_height_attribute_name
	statistic = initial_statistic


func get_value(game_object):
	var image_data = game_object.geo_feature.get_binary_attribute(image_attribute_name)
	var width = game_object.geo_feature.get_attribute(width_attribute_name)
	var height = game_object.geo_feature.get_attribute(height_attribute_name)
	
	var image = Image.create_from_data(width, height, false, Image.FORMAT_R8, image_data)
	
	if statistic == "Average":
		# Downscale to a set resolution, then calculate the average of pixel values from that
		# This allows for a trade-off between performance and accuracy
		var downscale_resolution = 10
		
		image.resize(downscale_resolution, downscale_resolution, Image.INTERPOLATE_BILINEAR)
		var sum = 0.0
		for x in range(downscale_resolution):
			for y in range(downscale_resolution):
				sum += image.get_pixel(x, y).a
		
		return sum / (downscale_resolution * downscale_resolution)
	else:
		# Unimplemented
		logger.warn("Unimplemented ImageFieldGameObjectAttribute statistic %s!" % [statistic])
		return 0.0


# set_value is not implemented, this attribute is read-only
