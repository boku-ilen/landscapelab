extends Button


@export var player_node: Node3D
const SCENE = preload("res://UI/LabTable/LabTable.tscn")


func _ready():
	var labtable_scene = SCENE.instantiate()
	labtable_scene.get_node("LabTable").debug_mode = false
	labtable_scene.get_node("LabTable").player_node = player_node
	pressed.connect(add_child.bind(labtable_scene))
