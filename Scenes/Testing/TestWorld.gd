extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var time = 0

func _process(delta):
	time += delta
	
	if time > 3:
		get_node("TileSpawner/test_0").split()
		
	if time > 6:
		get_node("TileSpawner/test_0").get_child(4).split()
		
	if time > 9:
		get_node("TileSpawner/test_0").get_child(4).get_child(4).split()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
