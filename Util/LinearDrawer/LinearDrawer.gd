extends Spatial


onready var curve = get_node("Path").curve


func add_points(points: Array):
	for point in points:
		add_point(point)


func add_point(point: Vector3):
	curve.add_point(point)
