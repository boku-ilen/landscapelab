tool
extends Spatial
class_name Module

#
# All modules which a WorldTile can spawn must inherit from this scene.
# It allows modules to easily access their parent tile.
#

var tile
var modules
var done = false

func _ready():
	if not get_parent() or not get_parent().get_parent():
		print("ERROR: Module is not correctly placed - grandparent must be a WorldTile! (WorldTile -> Modules -> This")
	else:
		tile = get_parent().get_parent()
		modules = get_parent()

# This function must be called when the module has finished loading! Otherwise, it is never considered ready to be
# displayed.
func done_loading():
	modules.emit_signal("module_done_loading")
	done = true