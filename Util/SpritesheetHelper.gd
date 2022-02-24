extends Object
class_name SpritesheetHelper


enum SCALING {
	STRETCH,
	KEEP_ASPECT
}

const LOG_MODULE := "SPRITESHEET"

# Turn the images in the given array into a spritesheet.
# The array is expected to be a 2-dimensional array with the first index being
#  the row, and the second index being the column.
# Possible scaling methods are KEEP_ASPECT (default), where the images are
#  rescaled to at most the given sprite_size (with the rest being transparency),
#  or STRETCH, where they get exactly the given sprite_size.
# An array of scale_factors, laid out identically to the images array, can be
#  given optionally. Each image is then scaled down by its corresponding factor.
static func create_spritesheet(
		sprite_size: Vector2,
		images: Array,
		scaling_method = SCALING.KEEP_ASPECT,
		scale_factors = null):
	# The number of rows and columns is given by the amount of images in the
	#  array
	var num_rows = images.size()
	
	# All images are assumed to be of the same format for now.
	# TODO: We could convert all images to a set format?
	var format = null
	
	for row in images:
		if row:
			for col in row:
				if col:
					format = col.get_format()
					break
	
	if format == null:
		# No valid images...
		logger.error("No valid images in the array given to create_spritesheet", LOG_MODULE)
		return null
	
	# Get the largest row (the row with the most columns) and use it as the
	#  number of columns in the spritesheet - if we chose an arbitrary one, the
	#  largest row might not fit
	var num_cols = 0
	for row in images:
		if row:
			var num_cols_in_row = row.size()
			if num_cols_in_row > num_cols:
				num_cols = num_cols_in_row
	
	# Create the image which will be filled with data, large enough to hold all
	#  rows and columns.
	var sheet = Image.new()
	sheet.create(sprite_size.x * num_cols,
			sprite_size.y * num_rows,
			false, format)
	
	# The current position on the sheet
	var current_offset = Vector2(0, 0)
	
	for y in num_rows:
		for x in num_cols:
			# It's plausible for a row to be empty. In this case, just continue
			#  with the next row.
			if not images[y]:
				break
			
			# It's possible that some rows don't fill all columns. If we're done
			#  with the columns for this row, break out of the inner loop
			if not x < images[y].size():
				break
			
			var sprite = images[y][x] as Image
			var desired_size = Vector2()
			
			if scaling_method == SCALING.STRETCH:
				desired_size = sprite_size
			elif scaling_method == SCALING.KEEP_ASPECT:
				desired_size = get_size_keep_aspect(sprite_size, sprite.get_size())
			
			if scale_factors:
				desired_size *= scale_factors[y][x]
			
			# Scale the sprite to the desired size
			sprite.resize(ceil(desired_size.x), ceil(desired_size.y))
	
			# We want the sprites to always be centered, so check how big the offset has to be
			var centering_offset = (sprite_size - desired_size) / 2
			
			# Place it at the bottom middle, not the center
			centering_offset.y *= 2
			
			# Add the scaled sprite to the spritesheet
			sheet.blit_rect(sprite, Rect2(Vector2(0, 0),
					Vector2(desired_size.x, desired_size.y)),
					current_offset + centering_offset)
			
			# Increment column position on spritesheet
			current_offset.x += sprite_size.x
		
		# Increment row position on spritesheet; reset column
		current_offset.x = 0
		current_offset.y += sprite_size.y
	
	return sheet


# Similar to `create_spritesheet`, but rather than multiple columns, multiple images are created and
#  returned inside an array.
# This has the advantage of decoupling the maximum number of columns from the maximum image
#  resolution, thus allowing a much higher amount of columns
static func create_layered_spritesheet(
		sprite_size: Vector2,
		images: Array,
		scaling_method = SCALING.KEEP_ASPECT):
	
	# All images are assumed to be of the same format for now.
	# TODO: We could convert all images to a set format?
	var format = null
	
	for row in images:
		if row:
			for col in row:
				if col:
					format = col.get_format()
					break
	
	if format == null:
		# No valid images...
		logger.warning("No valid images in the array given to create_spritesheet!", LOG_MODULE)
		return null
	
	var number_of_layers = images.size()
	var image_array = []
	image_array.resize(number_of_layers)
	
	var layer_depth = 0
	
	for layer_data in images:
		var number_of_images_in_layer = layer_data.size()
		
		var layer = Image.new()
		layer.create(sprite_size.x, sprite_size.y * number_of_images_in_layer, false, format)
		
		# The current position on the sheet
		var current_offset = Vector2(0, 0)
		
		for image in layer_data:
			var desired_size = Vector2()
			
			# It's plausible for individual images to be null -- in that case, that position is left empty
			if image:
				if scaling_method == SCALING.STRETCH:
					desired_size = sprite_size
				elif scaling_method == SCALING.KEEP_ASPECT:
					desired_size = get_size_keep_aspect(sprite_size, image.get_size())
				
				# Scale the sprite to the desired size
				image.resize(ceil(desired_size.x), ceil(desired_size.y))
		
				# We want the sprites to always be centered, so check how big the offset has to be
				var centering_offset = (sprite_size - desired_size) / 2
				
				# Place it at the bottom middle, not the center
				centering_offset.y *= 2
				
				# Add the scaled sprite to the spritesheet
				layer.blit_rect(image, Rect2(Vector2(0, 0),
						Vector2(desired_size.x, desired_size.y)),
						current_offset + centering_offset)
			
			# Increment column position on spritesheet
			current_offset.y += sprite_size.y
		
		image_array[layer_depth] = layer
		layer_depth += 1
	
	return image_array


static func get_size_keep_aspect(max_size, original_size):
	# Ratio of width to height -> Greater than 1 means the image is
	#  wider than it is high ("landscape")
	var current_aspect = original_size.x / original_size.y
	var desired_aspect = max_size.x / max_size.y
	
	if current_aspect == desired_aspect:
		# The aspect matches -> Direct downscale
		return max_size
	elif current_aspect > desired_aspect:
		# The current image is too wide -> Maximize width, smaller height
		var current_width = original_size.x
		
		return Vector2(max_size.x, int(max_size.x / current_aspect))
	else:
		# The current image is too high -> Maximize height, smaller width
		var current_height = original_size.y
		
		return Vector2(int(max_size.y * current_aspect), max_size.y)
