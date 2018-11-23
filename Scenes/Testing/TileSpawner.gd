tool
extends Spatial

var tile = preload("res://Scenes/Testing/WorldTile.tscn")
var gridsize = 100

func _ready():
	var num = 0
	
	for y in range(0, 20):
		for x in range(0, 20):
			#var map = load("res://Scenes/Testing/testlandia/test_%d.png" % [num])
			var map_img = Image.new() # TODO testing only
			map_img.load("res://Scenes/Testing/testlandia/test_%d.png" % [num])
			var map = ImageTexture.new()
			map.create_from_image(map_img)
	
			var tile_instance = tile.instance()
			tile_instance.name = "test_%d" % [num]
			tile_instance.translation = translation + Vector3(x * -gridsize, 0, y * -gridsize)
			
			add_child(tile_instance)
			
			get_node("test_%d" % [num]).init(gridsize, map, map, map_img)
			
			num += 1