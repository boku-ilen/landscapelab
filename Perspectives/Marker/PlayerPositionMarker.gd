extends Spatial

#
# A Sprite3D marker that is displayed in 3rd person view and on the minimap
# at the latest global player position from PlayerInfo.
#

onready var sprite = get_node("Sprite3D")


func _ready():
	PlayerInfo.connect("player_position_changed", self, "_on_new_player_position")


func _on_new_player_position(new_pos):
	# Update the position of the sprite according the new global player position
	# FIXME: It seems like the marker can flicker slightly when the world is shifted.
	#  Is this caused by a signal race condition?
	sprite.translation = new_pos
