extends Path3D


var visualizer: CSGPolygon3D :
	get:
		return visualizer # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_visualizer


func set_visualizer(vis):
	visualizer = vis
	$PathFollow3D.add_child(visualizer)
