extends CSGPolygon3D


var point_area = preload("res://UI/Layers/LayerConfiguration/Misc/ProfileEditor/PolygonPoint.tscn")
var profile_polygon: Array

var color :
	get:
		return color # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_color


func set_color(color):
	color = color
	for point in profile_polygon:
		point.line_to_next.material_override.albedo_color = color


func _ready():
	_create_collision_points()
	update()


func _create_collision_points():
	for point in polygon:
		var instance = point_area.instantiate()
		profile_polygon.append(instance)
		add_child(instance)
		instance.set_position(point)


func update():
	var temp: PackedVector2Array = []
	var idx = 0
	var point_before
	for point in profile_polygon:
		point.idx = idx
		temp.append(point.position)
		idx += 1
		if point_before: 
			draw_line(point_before, point)
		point_before = point
	
	# Finish the line
	draw_line(profile_polygon.back(), profile_polygon.front())
	
	set_polygon(temp)


func draw_line(point1, point2):
	point1.line_to_next.clear()
	point1.line_to_next.begin(Mesh.PRIMITIVE_LINES)
	point1.line_to_next.add_vertex(Vector3(point1.position.x, point1.position.y, 0))
	point1.line_to_next.add_vertex(Vector3(point2.position.x, point2.position.y, 0))
	point1.line_to_next.end()


func drag():
	var temp: PackedVector2Array = []
	for point in profile_polygon:
		temp.append(point.position)
	
	set_polygon(temp)
	update()


func delete_point(idx: int):
	var temp = profile_polygon[idx]
	profile_polygon.remove_at(idx)
	temp.queue_free()
	update()


func add_point(point):
	add_child(point)
	point.position = Vector2(0, 0)
	profile_polygon.append(point)
	update()


func duplicate_as_primitive_material():
	var primitive = CSGPolygon3D.new()
	primitive.polygon = polygon
	primitive.mode = mode
	primitive.path_node = path_node
	primitive.invert_faces = true
	return primitive
