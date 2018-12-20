extends Spatial

var tile = preload("res://Scenes/Testing/LOD/WorldTile.tscn")
var gridsize = 5000

onready var player = get_tree().get_root().get_node("TestWorld/ViewportContainer/Viewport/Controller")
onready var tiles = get_node("Tiles")

# Every update_interval seconds, the world will check what tiles to spawn/activate
export var update_interval = 0.1
var time_to_interval = 0

# When a player coordinate gets bigger than this, the world will be shifted to get the player back to the world origin
var shift_limit = 3000

var world_offset_x = int(0)
var world_offset_z = int(0)

# Radii for spawning and removing tiles
# Actually not really radii atm - currently rectangles
var tiles_radius = 10
var removal_radius_summand = 4
			
func _process(delta):
	time_to_interval += delta
	
	if time_to_interval >= update_interval: # Update
		time_to_interval -= update_interval
		var player_tile = get_tile_at_player()
		if player_tile == null: return
		
		# Loop through the entire rectangle (tiles_radius + removal_radius_summand)
		# remove tiles that are outside the smaller spawning-rectangle, add tiles that are inside the spawning-rectangle
		for x in range(player_tile.x - tiles_radius - removal_radius_summand, player_tile.x + tiles_radius + 1 + removal_radius_summand):
			for y in range(player_tile.y - tiles_radius - removal_radius_summand, player_tile.y + tiles_radius + 1 + removal_radius_summand):
				if (x in range(player_tile.x - tiles_radius, player_tile.x + tiles_radius + 1)
				and y in range(player_tile.y - tiles_radius, player_tile.y + tiles_radius + 1)):
					if not tiles.has_node("%d,%d" % [x, y]):
						# There is no tile here yet -> spawn the proper tile
						# TODO: Concurrency issues with offset position
						#ThreadPool.enqueue_task(ThreadPool.Task.new(self, "spawn_tile", [x, y]))
						spawn_tile([x, y])
				else:
					if tiles.has_node("%d,%d" % [x, y]):
						tiles.get_node("%d,%d" % [x, y]).queue_free()
					
		
#		# Spawn tiles around the player
#		for x in range(player_tile.x - tiles_radius, player_tile.x + tiles_radius + 1):
#			for y in range(player_tile.y - tiles_radius, player_tile.y + tiles_radius + 1):
#				if not tiles.has_node("%d,%d" % [x, y]):
#					# There is no tile here yet -> spawn the proper tile
#					# TODO: Concurrency issues with offset position
#					#ThreadPool.enqueue_task(ThreadPool.Task.new(self, "spawn_tile", [x, y]))
#					spawn_tile([x, y])
#				else:
#					# Keep this tile
#					pass
		
		# Activate 9 tiles closest to player
		for x in range(player_tile.x - 2, player_tile.x + 3):
			for y in range(player_tile.y - 2, player_tile.y + 3):
				if tiles.has_node("%d,%d" % [x, y]):
					tiles.get_node("%d,%d" % [x, y]).activate(player.translation)
					
		# Shift the world if the player exceeds the bounds
		var delta_vec = Vector3(0, 0, 0)
		
		if player.translation.x > shift_limit:
			delta_vec.x = -shift_limit
		elif player.translation.x < -shift_limit:
			delta_vec.x = shift_limit
		
		if player.translation.z > shift_limit:
			delta_vec.z = -shift_limit
		elif player.translation.z < -shift_limit:
			delta_vec.z = shift_limit
			
		player.shift(delta_vec)
		move_world(delta_vec)
		
func spawn_tile(pos):
	var map_img = Image.new() # TODO testing only
	map_img.load("res://Scenes/Testing/LOD/testlandia/test_1.png")
	var map = ImageTexture.new()
	map.create_from_image(map_img, 8)

	var tile_instance = tile.instance()
	tile_instance.name = "%d,%d" % [pos[0], pos[1]]
	tile_instance.translation = Vector3(pos[0] * -gridsize + world_offset_x, 0, pos[1] * -gridsize + world_offset_z)
	
	tile_instance.init(gridsize, map, map, map_img, 0)
	
	tiles.add_child(tile_instance)

# Moves all world tiles by delta_vec and remembers the total offset caused by using this function.
func move_world(delta_vec):
	world_offset_x += delta_vec.x
	world_offset_z += delta_vec.z
	
	for child in tiles.get_children():
		child.move(delta_vec)

# Gets the coordinates of the tile the player is currently standing on
func get_tile_at_player():
	var true_player = player.get_true_position()
	
	if player != null:
		var grid_vec = Vector2(-round((true_player[0]) / int(gridsize)), -round((true_player[1]) / int(gridsize)))
		return grid_vec
	else:
		return null