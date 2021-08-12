extends AutoTextureButton


export var vr_player: PackedScene
var pos_manager: PositionManager
var vr_player_instance: Spatial
var pc_player_instance: Spatial


func _toggled(button_pressed):
	if button_pressed:
		vr_player_instance = vr_player.instance()
		pos_manager.add_child(vr_player_instance)
		pc_player_instance = pos_manager.center_node
		pos_manager.center_node = vr_player_instance
	else:
		pass
