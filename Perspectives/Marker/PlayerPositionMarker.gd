extends Spatial

#
# A Sprite3D marker that is displayed in 3rd person view and on the minimap
# at the latest global player position from PlayerInfo.
#

onready var sprite = get_node("Sprite")
var direction : float


func _ready():
	PlayerInfo.connect("player_position_changed", self, "_on_new_player_position")
	PlayerInfo.connect("player_look_direction_changed", self, "_on_new_player_look_direction")


func _on_new_player_position(new_pos):
	# Update the position of the sprite according the new global player position
	# FIXME: It seems like the marker can flicker slightly when the world is shifted.
	#  Is this caused by a signal race condition?
	sprite.translation = new_pos


func _on_new_player_look_direction(new_dir):
	var player_look = Vector2(new_dir.x, new_dir.z)
	
	# look at https://stackoverflow.com/questions/14066933/direct-way-of-computing-clockwise-angle-between-2-vectors
	# this link for further information, as the global forward is (0, -1) the result looks like:
	direction = atan2(-player_look.x, -player_look.y)
	
	sprite.rotation.y = direction