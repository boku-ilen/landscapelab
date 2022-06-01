extends TextureRect

#
# Node that indicates the player orientation (north, east, south, west) as on
# a usual compass. Comparable to google earht
#

# injected from above
var pc_player: AbstractPlayer


func _ready():
	rect_pivot_offset = rect_size / 2


func _process(delta):
	rect_rotation = -rad2deg(pc_player.get_look_direction().signed_angle_to(Vector3.FORWARD, Vector3.UP))
