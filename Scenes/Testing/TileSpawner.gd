tool
extends Spatial

var tile = preload("res://Scenes/Testing/WorldTile.tscn")
var gridsize = 1000

onready var player = get_tree().get_root().get_node("TestWorld/ViewportContainer/Viewport/Controller")
var player_bound_radius = 50

var update_interval = 0.2
var time_to_interval = 0

func _ready():
	var num = 0
	
	for y in range(0, 20):
		for x in range(0, 20):
			#var map = load("res://Scenes/Testing/testlandia/test_%d.png" % [num])
			var map_img = Image.new() # TODO testing only
			map_img.load("res://Scenes/Testing/testlandia/test_%d.png" % [num])
			var map = ImageTexture.new()
			map.create_from_image(map_img, 8)
	
			var tile_instance = tile.instance()
			tile_instance.name = "%d,%d" % [x, y]
			tile_instance.translation = translation + Vector3(x * -gridsize, 0, y * -gridsize)
			
			add_child(tile_instance)
			
			get_node("%d,%d" % [x, y]).init(gridsize, map, map, map_img, 0)
			
			num += 1
			
func _process(delta):
	time_to_interval += delta
	
	if time_to_interval >= update_interval: # Update
		time_to_interval -= update_interval
		
		var player_tile = get_tile_at_player()
		if !player_tile: return
		
		# Activate 9 tiles closest to player
		for x in range(player_tile.x - 2, player_tile.x + 3):
			for y in range(player_tile.y - 2, player_tile.y + 3):
				if has_node("%d,%d" % [x, y]):
					get_node("%d,%d" % [x, y]).activate(Vector2(player.translation.x, player.translation.z))
		
func get_tile_at_player():
	if player != null:
		var grid_vec = Vector2(-round((player.translation.x - translation.x) / gridsize), -round((player.translation.z - translation.z) / gridsize))
		return grid_vec