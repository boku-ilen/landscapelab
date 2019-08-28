extends Module

#
# This module can be used by WorldTiles to create simple colliders for their terrain.
# For precise collisions at specific points, the WorldTile's get_height_at_position() should be used. This mesh serves only as an estimate.
#

onready var col_shape = get_node("StaticBody/CollisionShape")

var heightmap

var collider_subdivision = Settings.get_setting("terrain-collider", "collision-mesh-subdivision")


func _ready():
	connect("visibility_changed", self, "_on_visibility_changed")
	tile.thread_task(self, "get_textures", [])


# When this node becomes invisible due to higher LOD terrain being active, disable the collider
func _on_visibility_changed():
	if is_visible_in_tree():
		col_shape.disabled = true
	else:
		col_shape.disabled = false


func _on_ready():
	if heightmap:
		col_shape.shape = create_tile_collision_shape()
	else:
		logger.info("Couldn't get heightmap for tile!")
		
	ready_to_be_displayed()


func get_textures(data):
	var dhm_response = tile.get_texture_result("raster")
	if dhm_response and dhm_response.has("dhm"):
		heightmap = CachingImageTexture.get(dhm_response.get("dhm"), 0)
	
	make_ready()


# Returns the exact height at the given position using the heightmap image
func get_height_at_position(var pos):
	
	var gtranslation = tile.global_transform.origin
	var img
	
	if heightmap:
		img = heightmap.get_data()
	else:
		logger.warning("get_height_at_position was called, but the heightmap was null")
		return 0
	
	if img:
		# TODO: There is still a slight inconsistency with how the mesh actually looks here.
		# I believe that this might be because Godot's plane mesh has the triangles like this:
		#  ___
		# |  /|
		# | / |
		# |/__|
		# 
		# This makes them fold in a particular way which the linear interpolation can't predict.
		img.lock()
		
		var img_size = img.get_size()
		var subdiv = max(1, img_size.x / (tile.subdiv + 1))
		
		# Scale the position to a pixel position on the image
		var pos_scaled = (Vector2(pos.x, pos.z) - Vector2(gtranslation.x, gtranslation.z) + Vector2(tile.size / 2, tile.size / 2)) / tile.size
		var pix_pos = pos_scaled * img_size
		
		# We want to limit the accuracy here to what is actually displayed - otherwise, there are bumps
		#  and holes here which are not visible. So e.g. if we have a subdivision of 8 and 256 pixels,
		#  we clamp the values to 0, 32, 64, ... (256/8)
		var scaled_pix_pos = Vector2()
		scaled_pix_pos.x = int(pix_pos.x / subdiv) * subdiv
		scaled_pix_pos.y = int(pix_pos.y / subdiv) * subdiv
		
		# The factor by which the point we want is offset from the closest actual pixel
		# Used for interpolation later
		var xf = (pix_pos.x - scaled_pix_pos.x) / subdiv
		var yf = (pix_pos.y - scaled_pix_pos.y) / subdiv
		
		# Get multiple height samples, offset by the accuracy of our visible mesh
		var height1 = get_height_from_image(img, scaled_pix_pos + Vector2(0, 0) * subdiv)
		var height2 = get_height_from_image(img, scaled_pix_pos + Vector2(1, 0) * subdiv)
		var height3 = get_height_from_image(img, scaled_pix_pos + Vector2(0, 1) * subdiv)
		var height4 = get_height_from_image(img, scaled_pix_pos + Vector2(1, 1) * subdiv)
		
		img.unlock()
	
		# Bilinear interpolation of the height samples by the previous factors
		return lerp(lerp(height1, height2, xf), lerp(height3, height4, xf), yf)
		
	# if we do not have a valid height information we return 0   - TODO: error handling
	else:
		logger.warning("get_height_at_position was called, but the heightmap is not valid (it has no data)!")
		return 0
		

# Returns the height on the image at the given pixel position in meters.
func get_height_from_image(img, pix_pos):
	var img_size = img.get_size()
	
	pix_pos.x = clamp(pix_pos.x, 0, img_size.x - 1)
	pix_pos.y = clamp(pix_pos.y, 0, img_size.y - 1)
	
	return (img.get_pixel(pix_pos.x, pix_pos.y).r * 255 * pow(2, 16) \
		+ img.get_pixel(pix_pos.x, pix_pos.y).g * 255 * pow(2, 8) \
		+ img.get_pixel(pix_pos.x, pix_pos.y).b * 255) / 100


# Helper function for create_tile_collision_shape - turns x and y coordinates from the loop to a real position.
func _local_grid_to_coordinates(x, y, size, collider_subdivision):
	var local_pos = Vector3(-size/2 + (x/collider_subdivision) * size, 0, -size/2 + (y/collider_subdivision) * size)
	return Vector3(local_pos.x, get_height_at_position(global_transform * local_pos), local_pos.z)


# Creates a simple 4-vertices polygon which roughly corresponds to the heightmap, for use as a collider.
func create_tile_collision_shape():
	var shape = ConcavePolygonShape.new()
	var vecs = PoolVector3Array()
	var size = tile.size
	
	# Build a mesh with collider_subdivision * collider_subdivision vectors with the height
	#  at each position from the heightmap
	
	# TODO: It seems like the creation of the mesh isn't completely correct... There are some
	#  inaccuracies
	for x in range(0, collider_subdivision):
		for y in range(0, collider_subdivision):
			var top_left = _local_grid_to_coordinates(x, y, size, collider_subdivision)
			var top_right = _local_grid_to_coordinates(x + 1, y, size, collider_subdivision)
			var bottom_left = _local_grid_to_coordinates(x, y + 1, size, collider_subdivision)
			var bottom_right = _local_grid_to_coordinates(x + 1, y + 1, size, collider_subdivision)
			
			vecs.append(bottom_left)
			vecs.append(top_left)
			vecs.append(top_right)
			
			vecs.append(top_right)
			vecs.append(bottom_right)
			vecs.append(bottom_left)
	
	shape.set_faces(vecs)
	
	return shape
