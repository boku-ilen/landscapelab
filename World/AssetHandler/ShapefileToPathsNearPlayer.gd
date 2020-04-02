extends Spatial


#
# Extracts Curves near the global player position from a shapefile with Geodot
# and instances them in Paths. 
#


export(PackedScene) var path_scene

var shapefile_path = GeodataPaths.get_absolute_with_ending("infrastructure")
var radius = 500
var max_lines = 100

var load_thread: Thread = Thread.new()


func _get_line_array():
	var player_pos = PlayerInfo.get_true_player_position()
	return Geodot.get_lines(shapefile_path, -player_pos[0], player_pos[2], radius, max_lines)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("Timer").connect("timeout", self, "_on_timeout")


func _get_all_lines(data):
	var lines = _get_line_array()
	var root = Spatial.new()
	
	for line in lines:
		root.add_child(_get_path_node_for_line(line))
	
	call_deferred("_lines_received")
	return root


func _lines_received():
	var line_root = load_thread.wait_to_finish()
	line_root.name = "Lines"
	
	if has_node("Lines"):
		get_node("Lines").free()
	
	add_child(line_root)


func _on_timeout():
	if not load_thread.is_active():
		load_thread.start(self, "_get_all_lines")


func _get_path_node_for_line(line):
	var curve = line.get_offset_curve3d(Offset.x, 0, -Offset.z) as Curve3D
	var drawer = path_scene.instance() as LinearDrawer
	
	drawer.set_curve(curve)
	drawer.set_width(float(line.get_attribute("WIDTH")))
	
	return drawer
