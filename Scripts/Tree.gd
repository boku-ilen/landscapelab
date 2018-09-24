extends Spatial


func _ready():
	pass

#func _process(delta):
#	pass

func set_model(modelType):
	var mi = MeshInstance.new()
	add_child(mi)
	mi.set_mesh(modelType)
	pass


func update_position():
	var position = transform.origin
	var vert = Vector3(0,1000,0)
	#TODO might want to scale the up vert to max height so that no trees are left out in higher terrain
	
	var space_state = get_world().direct_space_state
	var resultUp = space_state.intersect_ray(position, position + vert)
	var resultDown = space_state.intersect_ray(position, position - vert)
	
	if not resultUp.empty():
		global_transform.origin = resultUp.position
	elif not resultDown.empty():
		global_transform.origin = resultDown.position