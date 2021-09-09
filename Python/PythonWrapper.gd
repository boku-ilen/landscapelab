extends Node


export(String, FILE, "*.tscn") var scene_to_load

var _is_python_node_instanced := false


func _ready():
	if Python.is_available():
		add_child(load(scene_to_load).instance())
		_is_python_node_instanced = true


func has_python_node() -> bool:
	return _is_python_node_instanced


func get_python_node():
	return get_child(0)
