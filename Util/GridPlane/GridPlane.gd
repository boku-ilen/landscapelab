extends Spatial

export var lines: int setget set_lines
export var grid_size: int = 1
export var show_cs: bool = true

var material

func _ready():
	material = SpatialMaterial.new()
	material.vertex_color_use_as_albedo = true
	material.flags_unshaded = true
	
	if show_cs:
		var line_x = ImmediateGeometry.new()
		line_x.material_override = material
		add_child(line_x)
		line_x.clear()
		line_x.begin(Mesh.PRIMITIVE_LINES)
		line_x.set_color(Color.red)
		line_x.add_vertex(Vector3(0, 0, 0))
		line_x.add_vertex(Vector3(0, 0, -1))
		line_x.end()
		
		var line_z = ImmediateGeometry.new()
		line_z.material_override = material
		add_child(line_z)
		line_z.clear()
		line_z.begin(Mesh.PRIMITIVE_LINES)
		line_z.set_color(Color.green)
		line_z.add_vertex(Vector3(0, 0, 0))
		line_z.add_vertex(Vector3(1, 0, 0))
		line_z.end()


func set_lines(lines: int):
	# Rows
	for i in range(lines):
		var line = ImmediateGeometry.new()
		line.material_override = material
		line.translation -= Vector3(lines / 2, 0, lines / 2)
		add_child(line)
		line.clear()
		line.begin(Mesh.PRIMITIVE_LINES)
		line.add_vertex(Vector3(0, 0, i * grid_size))
		line.add_vertex(Vector3(lines - 1, 0, i * grid_size))
		line.end()

	# Columns
	for i in range(lines):
		var line = ImmediateGeometry.new()
		line.material_override = material
		line.translation -= Vector3(lines / 2, 0, lines / 2)
		add_child(line)
		line.clear()
		line.begin(Mesh.PRIMITIVE_LINES)
		line.add_vertex(Vector3(i * grid_size, 0, 0))
		line.add_vertex(Vector3(i * grid_size, 0, lines - 1))
		line.end()
