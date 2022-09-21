extends Node


@export var scene_to_load: String # FIXME: (String, FILE, "*.tscn")

var _is_python_node_instanced := false


func _ready():
	if Python.is_available():
		add_child(load(scene_to_load).instantiate())
		_is_python_node_instanced = true


func has_python_node() -> bool:
	return _is_python_node_instanced


func get_python_node():
	return get_child(0)
