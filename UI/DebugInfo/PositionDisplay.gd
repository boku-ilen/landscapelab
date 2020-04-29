extends HBoxContainer

onready var label = get_node("Data")


func _process(delta: float) -> void:
	# Change the label text to show the current player position
	var player_pos = PlayerInfo.get_true_player_position()
	
	label.text = "%d, %d, %d" % [player_pos[0], player_pos[1], player_pos[2]]
