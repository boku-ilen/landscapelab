tool
extends Spatial

var tile = preload("res://Scenes/Testing/LOD/WorldTile.tscn")
var gridsize = 5000

onready var player = get_tree().get_root().get_node("TestWorld/ViewportContainer/Viewport/Controller")

var update_interval = 0.1
var time_to_interval = 0

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
			
			add_child(tile_instance)
			
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
				if not has_node("%d,%d" % [x, y]):
					# Spawn the proper tile
					var map_img = Image.new() # TODO testing only
					map_img.load("res://Scenes/Testing/LOD/testlandia/test_1.png")
					var map = ImageTexture.new()
					map.create_from_image(map_img, 8)
			
					var tile_instance = tile.instance()
					tile_instance.name = "%d,%d" % [x, y]
					tile_instance.translation = translation + Vector3(x * -gridsize, 0, y * -gridsize)
					
					tile_instance.init(gridsize, map, map, map_img, 0)
					
					add_child(tile_instance)
		
		# Activate 9 tiles closest to player
		for x in range(player_tile.x - 2, player_tile.x + 3):
			for y in range(player_tile.y - 2, player_tile.y + 3):
				if has_node("%d,%d" % [x, y]):
					get_node("%d,%d" % [x, y]).activate(player.translation)
		
func get_tile_at_player():
	if player != null:
		var grid_vec = Vector2(-round((player.translation.x - translation.x) / gridsize), -round((player.translation.z - translation.z) / gridsize))
		return grid_vec