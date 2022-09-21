extends Path3D


var visualizer: CSGPolygon3D :
	get:
		return visualizer
	set(vis):
		visualizer = vis
		$PathFollow3D.add_child(visualizer)
