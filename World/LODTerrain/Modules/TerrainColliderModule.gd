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
		
		var pos_scaled = (Vector2(pos.x, pos.z) - Vector2(gtranslation.x, gtranslation.z) + Vector2(tile.size / 2, tile.size / 2)) / tile.size
		var pix_pos = pos_scaled * img_size
		
		# Clamp to max values
		pix_pos.x = clamp(pix_pos.x, 0, img_size.x - 1)
		pix_pos.y = clamp(pix_pos.y, 0, img_size.y - 1)
		
		# Get height according to the specification of our heightmaps
		var height = img.get_pixel(pix_pos.x, pix_pos.y).r * 255 * pow(2, 16) \
			+ img.get_pixel(pix_pos.x, pix_pos.y).g * 255 * pow(2, 8) \
			+ img.get_pixel(pix_pos.x, pix_pos.y).b * 255
		
		# Millimeters to meters
		height /= 100
		
		img.unlock()
	
		return height
		
	# if we do not have a valid height information we return 0   - TODO: error handling
	else:
		logger.warning("get_height_at_position was called, but the heightmap is not valid (it has no data)!")
		return 0


# Creates a simple 4-vertices polygon which roughly corresponds to the heightmap, for use as a collider.
func create_tile_collision_shape():
	var shape = ConvexPolygonShape.new()
	var vecs = PoolVector3Array()
	var size = tile.size
	
	# Build a mesh with collider_subdivision * collider_subdivision vectors with the height
	#  at each position from the heightmap
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
