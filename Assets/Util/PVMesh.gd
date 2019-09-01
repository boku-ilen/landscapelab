extends Spatial


func _ready():
	# Put on ground
	# TODO: This needs to be redone when the tile this asset is on splits or
	#  if the mesh moves
	global_transform.origin = WorldPosition.get_position_on_ground(global_transform.origin)