extends Module

#
# This module can be used by WorldTiles to create simple colliders for their terrain.
# For precise collisions at specific points, the WorldTile's get_height_at_position() should be used. This mesh serves only as an estimate.
#

onready var col_shape = get_node("StaticBody/CollisionShape")

func _ready():
	col_shape.shape = create_tile_collision_shape()
	
	done_loading()
	
# Creates a simple 4-vertices polygon which roughly corresponds to the heightmap, for use as a collider.
func create_tile_collision_shape():
	var shape = ConvexPolygonShape.new()
	var vecs = PoolVector3Array()
	var size = tile.size
	
	vecs.append(Vector3(size/2, tile.get_height_at_position(translation + Vector3(size/2, 0, size/2)), size/2))
	vecs.append(Vector3(-size/2, tile.get_height_at_position(translation + Vector3(-size/2, 0, size/2)), size/2))
	vecs.append(Vector3(-size/2, tile.get_height_at_position(translation + Vector3(-size/2, 0, -size/2)), -size/2))
	vecs.append(Vector3(size/2, tile.get_height_at_position(translation + Vector3(size/2, 0, -size/2)), -size/2))
	
	shape.points = vecs
	
	return shape