extends Spatial
tool

export var lines: int setget set_lines
export var grid_size: int = 1


func _ready():
	var test = get_node("LineContainer")
	var bla = null


func set_lines(amount: int):
	lines = amount
	# Rows
	for i in range(lines):
		var line = ImmediateGeometry.new()
		line.set_color(Color.red)
		add_child(line)
		line.clear()
		line.begin(Mesh.PRIMITIVE_LINES)
		line.add_vertex(Vector3(0, 0, i * grid_size))
		line.add_vertex(Vector3(lines - 1, 0, i * grid_size))
		line.end()
	
	# Columns
	for i in range(lines):
		var line = ImmediateGeometry.new()
		line.set_color(Color.red)
		add_child(line)
		line.clear()
		line.begin(Mesh.PRIMITIVE_LINES)
		line.add_vertex(Vector3(i * grid_size, 0, 0))
		line.add_vertex(Vector3(i * grid_size, 0, lines - 1))
		line.end()
