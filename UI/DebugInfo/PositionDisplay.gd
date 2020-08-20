extends HBoxContainer

onready var label = get_node("Data")


func _process(delta: float) -> void:
	# Change the label text to show the current player position
	# TODO: Remove of fix this.
	
	label.text = "FIXME"
