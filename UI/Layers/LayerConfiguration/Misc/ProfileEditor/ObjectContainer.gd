extends VBoxContainer


func _add_object(world):
	var object = load(get_node("ObjectChooser/FileName").text).instance()
	world.add_child(object)
	object.translation = Vector3.ZERO


func _scale_object(object: Spatial):
	if object:
		var scale = Vector3(get_node("ScalingBox/X").value, 
			get_node("ScalingBox/Y").value, get_node("ScalingBox/Z").value)
		object.scale(scale)
