extends KinematicBody
class_name AbstractPlayer

var has_moved : bool = false
export var is_main_perspective : bool

func _ready():
	Offset.connect("shift_world", self, "shift")


func _physics_process(delta):
	if has_moved and is_main_perspective:
		PlayerInfo.update_player_pos(translation)
		has_moved = false
	else:
		if PlayerInfo.is_follow_enabled:
			translation.x = PlayerInfo.get_engine_player_position().x
			translation.z = PlayerInfo.get_engine_player_position().z


# Shift the player's in-engine translation by a certain offset, but not the player's true coordinates.
func shift(delta_x, delta_z):
	PlayerInfo.add_player_pos(Vector3(delta_x, 0, delta_z))
	
	translation.x += delta_x
	translation.z += delta_z