extends Spatial
class_name Module

#
# All modules which a WorldTile can spawn must inherit from this scene.
# It allows modules to easily access their parent tile.
#

var tile
var modules

signal module_done_loading
signal module_to_be_displayed


func init(tile):
	pass


func _done_loading():
	emit_signal("module_done_loading")
	

# When the tile is successfully loaded and should be displayed, this function should be called.
# Note: If there is a module which never calls it, the tile will never be displayed!
func _ready_to_be_displayed():
	emit_signal("module_to_be_displayed")
