extends Button

const SCENE = preload("res://UI/LabTable/LabTable.tscn")


func _ready():
	var labtable_scene = SCENE.instantiate()
	labtable_scene.get_node("LabTable").debug_mode = false
	pressed.connect(add_child.bind(labtable_scene))
