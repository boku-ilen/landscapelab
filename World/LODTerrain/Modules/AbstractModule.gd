extends Spatial
class_name Module

#
# All modules which a WorldTile can spawn must inherit from this scene.
# It allows modules to easily access their parent tile.
#

var tile
var modules

signal module_done_loading


# Override with the functionality to setup the module.
# Called in a thread, so blocking tasks can be performed here.
func init():
	pass


# To be called by the ModuleHandler which this module belongs to, giving it a
#  reference to the tile.
func set_tile(tile):
	assert(tile != null)
	
	self.tile = tile

# Call this function when the tile has fetched all its data.
func _done_loading():
	emit_signal("module_done_loading")
