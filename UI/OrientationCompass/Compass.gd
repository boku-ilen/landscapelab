extends Spatial

#
# A compass indicating the orientation of the firstPerson.
# Rotates with the latest global player position from PlayerInfo.
#

onready var parent = get_parent()
var direction : float

func _process(delta):
	var player_look = Vector2(transform.basis.z.x, transform.basis.z.z)
	
	# look at https://stackoverflow.com/questions/14066933/direct-way-of-computing-clockwise-angle-between-2-vectors
	# this link for further information, as the global forward is (0, -1) the result looks like:
	direction = atan2(-player_look.x, -player_look.y)
	
	global_transform = Transform.IDENTITY
	global_transform.origin = parent.global_transform.origin
