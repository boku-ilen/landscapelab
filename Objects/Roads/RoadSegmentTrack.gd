extends LineSegment


var width


func setup(new_feature):
	feature = new_feature
	
	width = float(feature.get_attribute("width"))
	var highway_attr = feature.get_attribute("highway")
	
	if width == 0.0:
		width = 3.0
	
	material_override.set_shader_parameter("width", width)
	
	var grade = feature.get_attribute("tracktype")
	
	var surface = feature.get_attribute("surface")
	
	var lid_center
	var lid_edge
	var lid_outer_edge
	var lid_track
	
	if surface and not surface.is_empty():
		if surface == "grass":
			lid_center = 7501
			lid_edge = 0
			lid_track = 7501
			lid_outer_edge = 0
		elif surface == "asphalt":
			lid_center = 2001
			lid_edge = 2001
			lid_track = 2001
			lid_outer_edge = 7502
	
	if not lid_center:
		if grade == "grade1":
			lid_center = 2001
			lid_edge = 2001
			lid_track = 2001
			lid_outer_edge = 7502
		elif grade == "grade2":
			lid_center = 10000
			lid_edge = 10000
			lid_track = 2001
			lid_outer_edge = 7502
		else:
			lid_center = 7501
			lid_edge = 7502
			lid_track = 10000
			lid_outer_edge = 7503
	
	material_override.set_shader_parameter("lid_color_center", Color8(
		lid_center % 255,
		floor(lid_center / 255),
		0
	))
	material_override.set_shader_parameter("lid_color_edge", Color8(
		lid_edge % 255,
		floor(lid_edge / 255),
		0
	))
	material_override.set_shader_parameter("lid_color_track", Color8(
		lid_track % 255,
		floor(lid_track / 255),
		0
	))
	material_override.set_shader_parameter("lid_color_outer_edge", Color8(
		lid_outer_edge % 255,
		floor(lid_outer_edge / 255),
		0
	))


func get_mesh_aabb():
	return mesh.get_aabb().grow(width)
