extends Module

#
# This module can be used by WorldTiles to create simple colliders for their terrain.
# For precise collisions at specific points, the WorldTile's get_height_at_position() should be used. This mesh serves only as an estimate.
#

onready var col_shape = get_node("StaticBody/CollisionShape")

var heightmap


func _ready():
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_textures", []))


func _on_ready():
	if heightmap:
		col_shape.shape = create_tile_collision_shape()
	else:
		logger.info("Couldn't get heightmap for tile!")


func get_textures(data):
	var zoom = tile.get_osm_zoom()
	
	# Orthophoto and heightmap
	heightmap = tile.get_texture_recursive("dhm", zoom, 0)
	
	make_ready()


# Returns the exact height at the given position using the heightmap image
func get_height_at_position(var pos):
	var img = heightmap.get_data()
	var gtranslation = tile.global_transform.origin
	
	if img:
		img.lock()
		var pos_scaled = (Vector2(pos.x, pos.z) - Vector2(gtranslation.x, gtranslation.z) + Vector2(tile.size / 2, tile.size / 2)) / tile.size
		var pix_pos = pos_scaled * img.get_size()
		
		# Clamp to max values
		pix_pos.x = clamp(pix_pos.x, 0, img.get_size().x - 1)
		pix_pos.y = clamp(pix_pos.y, 0, img.get_size().y - 1)
		
		var height = img.get_pixel(pix_pos.x, pix_pos.y).g * 500 # TODO: Centralize height range and use here
		img.unlock()
	
		return height
	else:
		return null


# Creates a simple 4-vertices polygon which roughly corresponds to the heightmap, for use as a collider.
func create_tile_collision_shape():
	var shape = ConvexPolygonShape.new()
	var vecs = PoolVector3Array()
	var size = tile.size
	
	vecs.append(Vector3(size/2, get_height_at_position(translation + Vector3(size/2, 0, size/2)), size/2))
	vecs.append(Vector3(-size/2, get_height_at_position(translation + Vector3(-size/2, 0, size/2)), size/2))
	vecs.append(Vector3(-size/2, get_height_at_position(translation + Vector3(-size/2, 0, -size/2)), -size/2))
	vecs.append(Vector3(size/2, get_height_at_position(translation + Vector3(size/2, 0, -size/2)), -size/2))
	
	shape.points = vecs
	
	return shape
