extends BoxContainer


export var vr_player: PackedScene
var pos_manager: PositionManager
var vr_player_instance: Spatial
var pc_player_instance: Spatial


func _ready():
	$HBoxContainer/InitVR.connect("toggled", self, "_toggle_vr")


func _toggle_vr(button_pressed):
	if button_pressed:
		vr_player_instance = vr_player.instance()
		pos_manager.add_child(vr_player_instance)
		pc_player_instance = pos_manager.center_node
		pos_manager.center_node = vr_player_instance
		pc_player_instance.queue_free()
		GameSystem.current_game_mode.game_object_collections["Players"].game_objects.values()[0].player_node = vr_player_instance
	else:
		pos_manager.remove_child(vr_player_instance)
		pos_manager.center_node = pc_player_instance
