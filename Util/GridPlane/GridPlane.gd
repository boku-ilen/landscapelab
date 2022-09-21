extends Node3D

@export var lines: int :
	get:
		return lines # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_lines
@export var grid_size: int = 1
@export var show_cs: bool = true

var material

func _ready():
	material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.flags_unshaded = true
	
	if show_cs:
		var line_x = ImmediateMesh.new()
		line_x.material_override = material
		line_x.clear()
		line_x.begin(Mesh.PRIMITIVE_LINES)
		line_x.set_color(Color.RED)
		line_x.add_vertex(Vector3(0, 0, 0))
		line_x.add_vertex(Vector3(0, 0, -1))
		line_x.end()
		
		var line_x_child = MeshInstance3D.new()
		line_x_child.mesh = line_x
		add_child(line_x_child)
		
		var line_z = ImmediateMesh.new()
		line_z.material_override = material
		line_z.clear()
		line_z.begin(Mesh.PRIMITIVE_LINES)
		line_z.set_color(Color.GREEN)
		line_z.add_vertex(Vector3(0, 0, 0))
		line_z.add_vertex(Vector3(1, 0, 0))
		line_z.end()
		
		var line_z_child = MeshInstance3D.new()
		line_z_child.mesh = line_z
		add_child(line_z_child)


func set_lines(lines: int):
	# Rows
	for i in range(lines):
		var line = ImmediateMesh.new()
		line.material_override = material
		line.position -= Vector3(lines / 2, 0, lines / 2)
		line.clear()
		line.begin(Mesh.PRIMITIVE_LINES)
		line.add_vertex(Vector3(0, 0, i * grid_size))
		line.add_vertex(Vector3(lines - 1, 0, i * grid_size))
		line.end()
		
		var line_child = MeshInstance3D.new()
		line_child.mesh = line
		add_child(line_child)

	# Columns
	for i in range(lines):
		var line = ImmediateMesh.new()
		line.material_override = material
		line.position -= Vector3(lines / 2, 0, lines / 2)
		line.clear()
		line.begin(Mesh.PRIMITIVE_LINES)
		line.add_vertex(Vector3(i * grid_size, 0, 0))
		line.add_vertex(Vector3(i * grid_size, 0, lines - 1))
		line.end()
		
		var line_child = MeshInstance3D.new()
		line_child.mesh = line
		add_child(line_child)
