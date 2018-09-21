extends Node

func mark_pos(v, s = 1):
	var sphere = preload("res://Scenes/debug_dot.tscn").instance()
	get_tree().get_root().get_node("main").add_child(sphere)
	sphere.global_transform.origin = v
	sphere.scale = Vector3(1,1,1)* s
	sphere.name = "debug_marker"
	