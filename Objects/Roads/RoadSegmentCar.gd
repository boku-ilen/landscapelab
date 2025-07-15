extends LineSegment


var width

static var highway_to_width_fallback = {
	"motorway": 10.0,
	"motorway_link": 6.0,
	"primary": 10.0,
	"primary_link": 6.0,
	"secondary": 8.0,
	"secondary_link": 7.0,
	"tertiary": 7.4,
	"tertiary_link": 7.0,
	"track": 3.0,
	"trunk": 5.0,
	"trunk_link": 4.0
}


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
		width = highway_to_width_fallback.get(highway_attr, 4.0)
	
	material_override.set_shader_parameter("width", width)
	
	# Don't make bridges write into the overlay layers
	material_override.set_shader_parameter("render_lid", feature.get_attribute("bridge") != "yes")
	material_override.set_shader_parameter("render_height", feature.get_attribute("bridge") != "yes")
	
	var lanes = max(int(feature.get_attribute("lanes")), 1)
	material_override.set_shader_parameter("lanes", lanes if width >= 5.0 else 1) # Avoid lanes smaller than 2.5


func get_mesh_aabb():
	return mesh.get_aabb().grow(width)
