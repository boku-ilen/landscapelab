extends HBoxContainer

@onready var label = get_node("Data")


func _process(_delta):
	label.text = str(Engine.get_frames_per_second())
