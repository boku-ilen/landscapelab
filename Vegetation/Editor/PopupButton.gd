extends Button


func _ready():
	connect("pressed", get_child(0), "popup")
