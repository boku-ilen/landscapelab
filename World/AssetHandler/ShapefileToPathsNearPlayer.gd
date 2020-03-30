extends Spatial


#
# Extracts Curves near the global player position from a shapefile with Geodot
# and instances them in Paths. 
#


export(PackedScene) var path_scene

var shapefile_path = GeodataPaths.get_absolute_with_ending("infrastructure")
var radius = 500
var max_lines = 20


func _get_line_array():
	var player_pos = PlayerInfo.get_true_player_position()
	
	return Geodot.get_lines(shapefile_path, -player_pos[0], player_pos[2], radius, max_lines)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("Timer").connect("timeout", self, "_on_timeout")


func _on_timeout():
	var lines = _get_line_array()
	
	for line in lines:
		spawn_path(line)


func spawn_path(line):
	var curve = line.get_offset_curve3d(Offset.x, 0, -Offset.z) as Curve3D
	var drawer = path_scene.instance() as LinearDrawer
	
	print(curve.get_baked_points()[4])
	
	drawer.set_curve(curve)
	drawer.set_width(float(line.get_attribute("WIDTH")))
	
	add_child(drawer)
