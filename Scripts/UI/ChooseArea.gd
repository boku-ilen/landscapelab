extends ItemList

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	self.connect("item_activated",self,"item_activated")
	#logger.debug("test")
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func item_activated(index):
	var main = get_tree().get_root().get_node("main")
	main.init_world(index)
	
	get_parent().get_parent().queue_free()