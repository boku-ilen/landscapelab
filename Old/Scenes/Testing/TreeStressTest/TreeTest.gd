extends Spatial

# This scene stress-tests the amount of trees which can be in a scene at a given time.
# On a GTX 980, approx. 10 000 shaded trees or 40 000 unshaded trees were possible with acceptable framerate (~15 FPS). 

var TreeScene = preload("res://Scenes/Tree.tscn")

# In total, (2*extent)^2 trees are spawned.
var extent = 100

func _ready():
	# Spawn a whole lot of trees!
	for x in range(-extent, extent):
		for y in range(-extent, extent):
			var tree = TreeScene.instance()
			tree.translation = Vector3(x * 10, 0, y * 10)
			add_child(tree)