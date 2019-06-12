extends Module

#
# This module can be used by WorldTiles to create simple colliders for their terrain.
# For precise collisions at specific points, the WorldTile's get_height_at_position() should be used. This mesh serves only as an estimate.
#

onready var col_shape = get_node("StaticBody/CollisionShape")

var heightmap

var collider_subdivision = Settings.get_setting("terrain-collider", "collision-mesh-subdivision")


func _ready():
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_textures", []))


func _on_ready():
	if heightmap:
		col_shape.shape = create_tile_collision_shape()
	else:
		logger.info("Couldn't get heightmap for tile!")
		
	ready_to_be_displayed()


func get_textures(data):
	var dhm_response = tile.get_texture_result("raster")
	if dhm_response and dhm_response.has("dhm"):
		heightmap = CachingImageTexture.get(dhm_response.get("dhm"))
	
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
		img.lock()
		
		var img_size = img.get_size()
		
		# Scale the position to a pixel position on the image
		var pos_scaled = (Vector2(pos.x, pos.z) - Vector2(gtranslation.x, gtranslation.z) + Vector2(tile.size / 2, tile.size / 2)) / tile.size
		var pix_pos = pos_scaled * img_size
		
		# The factor by which the point we want is offset from the closest actual pixel
		# Used for interpolation later
		var xf = (pix_pos.x - int(pix_pos.x) + int(pix_pos.x) % 16) / 16
		var yf = (pix_pos.y - int(pix_pos.y) + int(pix_pos.y) % 16) / 16
		
		# We want to limit the accuracy here to what is actually displayed - otherwise, there are bumps
		#  and holes which are not visible
		pix_pos.x = int(pix_pos.x) - int(pix_pos.x) % 16
		pix_pos.y = int(pix_pos.y) - int(pix_pos.y) % 16
		
		# Offset since we only add values later?
		pix_pos -= Vector2(8, 8)
		
		# Clamp to max values
		pix_pos.x = clamp(pix_pos.x, 0, img_size.x - 1)
		pix_pos.y = clamp(pix_pos.y, 0, img_size.y - 1)
		
		# Get multiple height samples, offset by the accuracy of our visible mesh
		var height1 = get_height_from_image(img, pix_pos + Vector2(0, 0))
		var height2 = get_height_from_image(img, pix_pos + Vector2(16, 0))
		var height3 = get_height_from_image(img, pix_pos + Vector2(0, 16))
		var height4 = get_height_from_image(img, pix_pos + Vector2(16, 16))
		
		img.unlock()
	
		# Bilinear interpolation of the height samples by the previous factors
		return lerp(lerp(height1, height2, xf), lerp(height3, height4, xf), yf)
		
	# if we do not have a valid height information we return 0   - TODO: error handling
	else:
		logger.warning("get_height_at_position was called, but the heightmap is not valid (it has no data)!")
		return 0
		

# Returns the height on the image at the given pixel position in meters.
func get_height_from_image(img, pix_pos):
	return (img.get_pixel(pix_pos.x, pix_pos.y).r * 255 * pow(2, 16) \
		+ img.get_pixel(pix_pos.x, pix_pos.y).g * 255 * pow(2, 8) \
		+ img.get_pixel(pix_pos.x, pix_pos.y).b * 255) / 100


# Creates a simple 4-vertices polygon which roughly corresponds to the heightmap, for use as a collider.
func create_tile_collision_shape():
	var shape = ConvexPolygonShape.new()
	var vecs = PoolVector3Array()
	var size = tile.size
	
	# Build a mesh with collider_subdivision * collider_subdivision vectors with the height
	#  at each position from the heightmap
	
	# TODO: It seems like the creation of the mesh isn't completely correct... There are some
	#  inaccuracies
	for x in range(0, collider_subdivision + 1):
		var start = 0
		var end = collider_subdivision + 1
		var step = 1
		
		# We alternate between going up and down every row, like this:
		# 1 2 3 4
		# 8 7 6 5
		# ...
		if x % 2 == 1:
			start = collider_subdivision + 1
			end = 0
			step = -1
			
		for y in range(start, end, step):
			var local_pos = Vector3(-size/2 + (x/collider_subdivision) * size, 0, -size/2 + (y/collider_subdivision) * size)
			var local_pos_correct_height = Vector3(local_pos.x, get_height_at_position(translation + local_pos), local_pos.z)
			
			vecs.append(local_pos_correct_height)
	
	shape.points = vecs
	
	return shape
