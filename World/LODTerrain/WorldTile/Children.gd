extends Spatial

onready var tile = get_parent()


# Here, the actual splitting happens - this function can be run in a thread
func instantiate_children(data):
	# The children are simply named from 0 to 3:
	#  ----> x
	# | 0 2
	# | 1 3
	# v y
	var cur_name = 0
	
	# Hide children while they're being built
	visible = false
	
	if has_node("0"): # The nodes are already there, but invisible
		for i in range(0, 3):
			get_node(str(i)).visible = true
	else:
		# Add 4 children
		for x in range(0, 2):
			for y in range(0, 2):
				var xy_vec = Vector2(x, y)
				
				var child = load("res://World/LODTerrain/WorldTile/WorldTile.tscn").instance()
				
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
	for child in get_children():
		child.delete()
		
	tile.num_children_loaded = 0