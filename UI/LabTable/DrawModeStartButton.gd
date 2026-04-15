extends TableButton

func _ready():
	# map change TODO
	pressed.connect(func (): 
		for n in get_tree().get_nodes_in_group("RegularUI"):
			if n is CanvasItem:
				n.visible = false
		for n in get_tree().get_nodes_in_group("DrawingUI"):
			if n is CanvasItem:
				n.visible = true
		)
	
