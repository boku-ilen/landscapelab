extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func update_position():
	var position = transform.origin
	var vert = Vector3(0,100000,0)
	#TODO might want to scale the up vert to max height so that no trees are left out in higher terrain
	
	if get_world():
		var space_state = get_world().direct_space_state
		var resultUp = space_state.intersect_ray(position, position + vert)
		var resultDown = space_state.intersect_ray(position, position - vert)
		
		if not resultUp.empty():
			global_transform.origin = resultUp.position
		elif not resultDown.empty():
			global_transform.origin = resultDown.position