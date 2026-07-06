extends Window


var pos_manager: PositionManager:
	set(new_pos_manager):
		pos_manager = new_pos_manager
		$PanelContainer/TeleportMenu.pos_manager = new_pos_manager

var pc_player: AbstractPlayer:
	set(new_pc_player):
		pc_player = new_pc_player
		$PanelContainer/TeleportMenu.pc_player = new_pc_player


func _ready():
	close_requested.connect(hide)
