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

func _ready():
	var num = 0
	
	for y in range(0, 20):
		for x in range(0, 20):
			#var map = load("res://Scenes/Testing/testlandia/test_%d.png" % [num])
			var map_img = Image.new() # TODO testing only
			map_img.load("res://Scenes/Testing/LOD/testlandia/test_%d.png" % [num])
			var map = ImageTexture.new()
			map.create_from_image(map_img, 8)
	
			var tile_instance = tile.instance()
			tile_instance.name = "%d,%d" % [x, y]
			tile_instance.translation = translation + Vector3(x * -gridsize, 0, y * -gridsize)
			
			tile_instance.init(gridsize, map, map, map_img, 0)
			
			tiles.add_child(tile_instance)
			
			num += 1
			
func _process(delta):
	time_to_interval += delta
	
	if time_to_interval >= update_interval: # Update
		time_to_interval -= update_interval
		
		var player_tile = get_tile_at_player()
		if !player_tile: return
		
		# Spawn tiles around the player
		for x in range(player_tile.x - 10, player_tile.x + 11):
			for y in range(player_tile.y - 10, player_tile.y + 11):
				if not tiles.has_node("%d,%d" % [x, y]):
					# Spawn the proper tile
					var map_img = Image.new() # TODO testing only
					map_img.load("res://Scenes/Testing/LOD/testlandia/test_1.png")
					var map = ImageTexture.new()
					map.create_from_image(map_img, 8)
			
					var tile_instance = tile.instance()
					tile_instance.name = "%d,%d" % [x, y]
					tile_instance.translation = Vector3(x * -gridsize + world_offset_x, 0, y * -gridsize + world_offset_z)
					
					tile_instance.init(gridsize, map, map, map_img, 0)
					
					tiles.add_child(tile_instance)
		
		# Activate 9 tiles closest to player
		for x in range(player_tile.x - 2, player_tile.x + 3):
			for y in range(player_tile.y - 2, player_tile.y + 3):
				if tiles.has_node("%d,%d" % [x, y]):
					tiles.get_node("%d,%d" % [x, y]).activate(player.translation)
					print(tiles.get_node("%d,%d" % [x, y]).translation)
					
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

# Moves all world tiles by delta_vec and remembers the total offset caused by using this function.
func move_world(delta_vec):
	world_offset_x += delta_vec.x
	world_offset_z += delta_vec.z
	
	for child in tiles.get_children():
		child.translation += delta_vec

# Gets the coordinates of the tile the player is currently standing on
func get_tile_at_player():
	var true_player = player.get_true_position()
	print(true_player)
	
	if player != null:
		var grid_vec = Vector2(-round((true_player[0]) / int(gridsize)), -round((true_player[1]) / int(gridsize)))
		print(grid_vec)
		return grid_vec