extends Path


var visualizer: CSGPolygon setget set_visualizer


func set_visualizer(vis):
	visualizer = vis
	$PathFollow.add_child(visualizer)
