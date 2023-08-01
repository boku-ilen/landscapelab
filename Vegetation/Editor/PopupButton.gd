extends Button


func _ready():
	connect("pressed",Callable(get_child(0),"popup"))
