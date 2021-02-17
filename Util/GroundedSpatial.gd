extends Spatial
class_name GroundedSpatial

#
# Standard Spatial node which can stay on the LODTerrain ground.
#


var tile_underneath: WorldTile

var _just_placed_on_ground = false

var pos_manager: PositionManager


func _ready():
	# Required to make the _notification with NOTIFICATION_TRANSFORM_CHANGED work
	set_notify_transform(true)
	
	_place_on_ground()


func _notification(what):
	# If the global position of this node has changed, get the tile this node is now on and
	#  place the node on the ground
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_inside_tree():
		# Without this flag, we would loop infinitely since we cause a NOTIFICATION_TRANSFORM_CHANGED
		#  inside _place_on_ground()!
		if _just_placed_on_ground:
			_just_placed_on_ground = false
		else:
			_place_on_ground()


# Puts the origin of the node on the ground.
func _place_on_ground():
	# FIXME: Update position: global_transform.origin = 
	
	_just_placed_on_ground = true


# React to a world shift
func shift(delta_x, delta_z):
	global_transform.origin += Vector3(delta_x, 0, delta_z)
	
	# Since this was a world shift, we don't need to get a new height
	_just_placed_on_ground = true
