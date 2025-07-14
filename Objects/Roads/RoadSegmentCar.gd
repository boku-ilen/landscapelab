extends LineSegment


var width


func _ready():
	LIDOverlay.updated.emit()
	visibility_changed.connect(func(): LIDOverlay.updated.emit())


func setup(new_feature):
	feature = new_feature
	
	var lid := 2002
	material_override.set_shader_parameter("lid_color", Color8(
		lid % 255,
		floor(lid / 255),
		0
	))
	
	width = float(feature.get_attribute("width"))
	var highway_attr = feature.get_attribute("highway")
	
	if width == 0.0:
		# Choose width based on highway attribute
		if highway_attr == "motorway":
			width = 10.0
		elif highway_attr == "motorway_link":
			width = 6.0
		elif highway_attr == "primary":
			width = 10.0
		elif highway_attr == "primary_link":
			width = 6.0
		elif highway_attr == "secondary":
			width = 8.0
		elif highway_attr == "secondary_link":
			width = 7.0
		elif highway_attr == "tertiary":
			width = 7.4
		elif highway_attr == "tertiary_link":
			width = 7.0
		elif highway_attr == "track":
			width = 3.0
		elif highway_attr == "trunk":
			width = 5.0
		elif highway_attr == "trunk_link":
			width = 4.0
		else:
			width = 4.0
	
	material_override.set_shader_parameter("width", width)
	
	# Don't make bridges write into the overlay layers
	material_override.set_shader_parameter("render_lid", feature.get_attribute("bridge") != "yes")
	material_override.set_shader_parameter("render_height", feature.get_attribute("bridge") != "yes")
	
	var lanes = max(int(feature.get_attribute("lanes")), 1)
	material_override.set_shader_parameter("lanes", lanes if width >= 5.0 else 1) # Avoid lanes smaller than 2.5


func get_mesh_aabb():
	return mesh.get_aabb().grow(width)
