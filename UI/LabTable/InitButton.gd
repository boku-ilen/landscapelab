extends Button

const SCENE = preload("res://UI/LabTable/LabTable.tscn")


func _ready():
	pressed.connect(
		func():
			add_child(SCENE.instantiate())
	)
