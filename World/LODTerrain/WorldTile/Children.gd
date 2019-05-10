extends Spatial

var tilescene = load("res://World/LODTerrain/WorldTile/WorldTile.tscn")

onready var tile = get_parent()


# Here, the actual splitting happens - this function can be run in a thread
func instantiate_children(data):
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
			
			var child = tilescene.instance()
			
			# Set location
			var offset = Vector3(x - 0.5, 0, y - 0.5)  * tile.size/2.0
			child.translation = offset
			
			child.offset_from_parent = xy_vec / 2 # fields are 0 or 0.5

			# Apply
			child.name = String(cur_name)
			cur_name += 1

			child.init((tile.size / 2.0), tile.lod + 1, tile.last_player_pos, data[0])
			child.connect("tile_done_loading", tile, "_on_child_tile_finished")

			call_deferred("add_child", child)
				
				
# Removes all the higher LOD children
func clear_children():
	tile.num_children_active = 0
	
	for child in get_children():
		child.name += "-deleting"
		child.delete()
		

# Returns true if all children are instanced and active
func are_all_active():
	if get_child_count() != tile.NUM_CHILDREN:
		return false
	
	for child in get_children():
		if (not child.done_loading) or (child.to_be_deleted):
			return false
	
	return true