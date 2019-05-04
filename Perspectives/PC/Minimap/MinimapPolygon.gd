extends Spatial

export(Array, Vector2) var points

func _ready():
	
	# convert Vector2 to Vector3
	var pts = []
	for p in points:
		pts.append(Vector3(p.x, 0, p.y))
	
	#get_node("MeshInstance").update_mesh(pts, 10.0)