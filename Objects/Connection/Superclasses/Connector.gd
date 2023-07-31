extends Node3D
class_name Connector

@export var load_radius := 500.0

func _ready():
	assert(get_node("Docks") != null)
