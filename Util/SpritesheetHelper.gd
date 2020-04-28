extends Object
class_name SpritesheetHelper


# Turn the images in the given array into a spritesheet.
# The array is expected to be a 2-dimensional array with the first index being
#  the row, and the second index being the column.
static func create_spritesheet(sprite_size: Vector2, images: Array):
	# The number of rows and columns is given by the amount of images in the
	#  array
	var num_rows = images.size()
	
	# All images are assumed to be of the same format for now.
	# TODO: We could convert all images to a set format?
	var format
	
	for row in images:
		if row:
			for col in row:
				if col:
					format = col.get_format()
					break
	
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
			var original_size = sprite.get_size()
			
			# Ratio of width to height -> Greater than 1 means the image is
			#  wider than it is high ("landscape")
			var current_aspect = original_size.x / original_size.y
			var desired_aspect = sprite_size.x / sprite_size.y
			
			var desired_size = Vector2()
			
			if current_aspect == desired_aspect:
				# The aspect matches -> Direct downscale
				desired_size = sprite_size
			elif current_aspect > desired_aspect:
				# The current image is too wide -> Maximize width, smaller height
				var current_width = original_size.x
				
				desired_size.x = sprite_size.x
				desired_size.y = int(desired_size.x / current_aspect)
			else:
				# The current image is too high -> Maximize height, smaller width
				var current_height = original_size.y
				
				desired_size.y = sprite_size.y
				desired_size.x = int(desired_size.y * current_aspect)
			
			# Scale the sprite to the desired size
			sprite.resize(desired_size.x, desired_size.y)
	
			# We want the sprites to always be centered, so check how big the offset has to be
			var centering_offset = (sprite_size - desired_size) / 2
			
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
