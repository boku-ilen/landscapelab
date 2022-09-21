extends TextureRect

#
# Node that indicates the player orientation (north, east, south, west) as checked
# a usual compass. Comparable to google earht
#

# injected from above
var pc_player: AbstractPlayer


func _ready():
	pivot_offset = size / 2


func _process(delta):
	rotation = -rad_to_deg(pc_player.get_look_direction().signed_angle_to(Vector3.FORWARD, Vector3.UP))
