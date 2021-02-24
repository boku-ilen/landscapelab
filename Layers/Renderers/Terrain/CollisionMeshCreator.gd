extends StaticBody

#
# Can be added as a child to a TerrainLOD to generate a collision StaticBody based on its data and
# shape.
#


export(int) var subdivision = 16


func _ready():
	connect("visibility_changed", self, "_on_visibility_changed")


# When this node becomes invisible (e.g. due to being hidden via the UI) disable the collider
func _on_visibility_changed():
	if is_visible_in_tree():
		$CollisionShape.disabled = false
	else:
		$CollisionShape.disabled = true


func create_mesh(heightmap_texture: ImageTexture, size: float):
	$CollisionShape.shape = create_collision_shape(heightmap_texture.get_data(), size)
	
	# Reset the scale of this node, as scaled colliders may yield wrong results
	global_transform = Transform.IDENTITY


# Returns the height on the image at the given pixel position in meters.
func _get_height_from_image(pix_pos, image):
	pix_pos.x = clamp(pix_pos.x, 0, image.get_width() - 1)
	pix_pos.y = clamp(pix_pos.y, 0, image.get_height() - 1)
	
	# Locking the image and using get_pixel takes about as long as manually
	#  getting the height from the PoolByteArray data, so this more intuitive
	#  way is used instead of a custom implementation, as previously.
	image.lock()
	var height = image.get_pixel(pix_pos.x, pix_pos.y).r
	image.unlock()
	
	return height


# Helper function for create_collision_shape - turns x and y coordinates from the loop to a real
#  position including the correct height.
func _get_3d_position(normalized_position, source_resolution, image, size):
	var local_pos = Vector3(
			-size/2 + normalized_position.x * size,
			0,
			-size/2 + normalized_position.y * size)
			
	var height = _get_height_from_image(normalized_position * source_resolution, image)
	
	return Vector3(local_pos.x, height, local_pos.z)


# Create a ConcavePolygonShape based on the given heightmap, with the given size as the extent.
func create_collision_shape(image, size):
	var shape = ConcavePolygonShape.new()
	var vecs = PoolVector3Array()
	var source_resolution = image.get_size()
	
	# Build a mesh with subdivision * subdivision vectors with the height at each position coming
	#  from the heightmap
	for x in range(0, subdivision):
		for y in range(0, subdivision):
			var mesh_position = Vector2(x, y)
			var normalized_position = mesh_position / subdivision
			
			var add = 1.0 / subdivision
			
			var top_left = _get_3d_position(normalized_position, source_resolution, image, size)
			var top_right = _get_3d_position(normalized_position + Vector2(add, 0), source_resolution, image, size)
			var bottom_left = _get_3d_position(normalized_position + Vector2(0, add), source_resolution, image, size)
			var bottom_right = _get_3d_position(normalized_position + Vector2(add, add), source_resolution, image, size)
			
			vecs.append(bottom_left)
			vecs.append(top_left)
			vecs.append(top_right)
			
			vecs.append(top_right)
			vecs.append(bottom_right)
			vecs.append(bottom_left)
	
	shape.set_faces(vecs)
	
	return shape
