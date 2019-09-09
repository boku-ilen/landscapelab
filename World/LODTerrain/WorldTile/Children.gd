extends Spatial

#
# This node must be a child of a WorldTile. It handles splitting and
# managing the child tiles according to the quadtree.
#

var tilescene = load("res://World/LODTerrain/WorldTile/WorldTile.tscn")

onready var tile = get_parent()

var _children_to_be_displayed = 0


# Here, the actual splitting happens - this function can be run in a thread
func instantiate_children():
	# The children are simply named from 0 to 3:
	#  ----> x
	# | 0 2
	# | 1 3
	# v y
	var cur_name = 0

	# Add 4 children
	for x in range(0, 2):
		for y in range(0, 2):
			var xy_vec = Vector2(x, y)
			
			var child = tilescene.instance() as WorldTile
			
			# Set location
			var offset = Vector3(x - 0.5, 0, y - 0.5)  * tile.size/2.0
			child.translation = offset
			
			child.offset_from_parent = xy_vec / 2 # fields are 0 or 0.5
			
			child.top_level = tile.top_level

			# Apply
			child.name = String(cur_name)
			cur_name += 1

			child.init((tile.size / 2.0), tile.lod + 1, tile.last_player_pos)
			
			child.connect("tile_to_be_displayed", self, "_on_child_to_be_displayed")

			add_child(child)


# Removes all the higher LOD children
func clear_children():
	for child in get_children():
		child.name += "-deleting"
		child.delete()


# Returns true if all children are instanced and active.
func are_all_active():
	if get_child_count() != tile.NUM_CHILDREN:
		return false
	
	for child in get_children():
		if (not child.done_loading) or (child.to_be_deleted):
			return false
	
	return true


func _on_child_to_be_displayed():
	_children_to_be_displayed += 1
	
	if _children_to_be_displayed == tile.NUM_CHILDREN:
		tile.emit_signal("all_children_to_be_displayed")


# Returns true if all children are ready to be displayed.
# Similar to are_all_active(), but with the additional check of to_be_displayed.
func are_all_to_be_displayed():
	if get_child_count() != tile.NUM_CHILDREN:
		return false
	
	for child in get_children():
		if (not child.to_be_displayed) or (not child.done_loading) or (child.to_be_deleted):
			return false
	
	return true