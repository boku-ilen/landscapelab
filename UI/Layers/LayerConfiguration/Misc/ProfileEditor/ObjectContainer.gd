extends VBoxContainer


var current_object :
	get:
		return current_object 
	set(object):
		current_object = object


func _ready():
	$ScalingBox/Apply.connect("pressed",Callable(self,"_scale_object"))


func _add_object(world, drag_handler):
	if FileAccess.file_exists(get_node("ObjectChooser/FileName").text):
		var object = load(get_node("ObjectChooser/FileName").text).instantiate()
		world.add_child(object, true)
		current_object = object
		object.position = Vector3.ZERO
		
		_recursively_create_colliders(object, object.name)
		
		drag_handler.dragables[object.name] = drag_handler.DragableObject.new(object)


# Recursively find all meshes and create trimesh colliders for them
func _recursively_create_colliders(object: Node3D, name: String):
	if not object: return
	
	for child in object.get_children():
		_recursively_create_colliders(child, name)
		
	if object is MeshInstance3D:
		object.create_convex_collision()
		if object.get_child_count():
			object.get_child(0).name = name


func _recursively_remove_colliders(object: Node3D, name: String):
	if not object: return
	
	for child in object.get_children():
		_recursively_remove_colliders(child, name)
		
	if object is MeshInstance3D:
		if object.get_child_count():
			object.remove_child(object.get_node(name))


func _scale_object():
	if current_object:
		current_object.set_scale(Vector3(get_node("ScalingBox/X").value, 
			get_node("ScalingBox/Y").value, get_node("ScalingBox/Z").value))


func _apply_reoccuring_object(path: Profile):
	if current_object:
		# store the position and reset it to zero 
		# this will be h- and v-offset of the path-follow later checked
		var position = current_object.position
		_recursively_remove_colliders(current_object, current_object.name)
		current_object.position = Vector3.ZERO
		var object_as_scene = PackedScene.new()
		object_as_scene.pack(current_object)
		
		var reoccurring = path.ReoccurringObject.new(
			position.x,
			position.y,
			$DistanceBox/SpinBox.value,
			object_as_scene 
		)
		
		path.add_reoccuring_object(reoccurring)
		current_object.queue_free()
