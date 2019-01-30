tool
extends Spatial
class_name Module

#
# All modules which a WorldTile can spawn must inherit from this scene.
# It allows modules to easily access their parent tile.
#

var tile

func _ready():
	if not get_parent() or not get_parent().get_parent():
		print("ERROR: Module is not correctly placed - grandparent must be a WorldTile! (WorldTile -> Modules -> This")
	else:
		tile = get_parent().get_parent()