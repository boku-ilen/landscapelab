extends LineSegment


var width

# Standard width values for 2 lanes
static var highway_to_width_fallback = {
	"motorway": 7.0,
	"motorway_link": 7.0,
	"primary": 7.0,
	"primary_link": 7.0,
	"trunk": 7.0,
	"trunk_link": 7.0,
	"secondary": 6.0,
	"secondary_link": 6.0,
	"tertiary": 6.0,
	"tertiary_link": 6.0,
	"residential": 5.0,
	"track": 5.0,
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
	
	var lanes = int(feature.get_attribute("lanes"))
	if lanes == 0: lanes = 2
	
	if width == 0.0:
		width = highway_to_width_fallback.get(highway_attr, 4.0)
	
	width *= (lanes / 2.0)
	
	material_override.set_shader_parameter("width", width)
	
	# Don't make bridges write into the overlay layers
	material_override.set_shader_parameter("render_lid", feature.get_attribute("bridge") != "yes")
	material_override.set_shader_parameter("render_height", feature.get_attribute("bridge") != "yes")
	
	material_override.set_shader_parameter("lanes", lanes)


func get_mesh_aabb():
	return mesh.get_aabb().grow(width)
