extends Sprite3D

#
# A compass indicating the orientation of the firstPerson.
# Rotates with the latest global player position from PlayerInfo.
#

var direction : float


func _ready():
	PlayerInfo.connect("player_look_direction_changed", self, "_on_new_player_look_direction")


func _on_new_player_look_direction(new_dir):
	var player_look = Vector2(new_dir.x, new_dir.z)
	
	# look at https://stackoverflow.com/questions/14066933/direct-way-of-computing-clockwise-angle-between-2-vectors
	# this link for further information, as the global forward is (0, -1) the result looks like:
	direction = atan2(-player_look.x, -player_look.y)
	
	rotation.z = -direction #+ deg2rad(180.0)