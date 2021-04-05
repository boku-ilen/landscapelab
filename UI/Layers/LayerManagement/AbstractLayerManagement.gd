extends Node
class_name AbstractLayerManagement


var pc_player: AbstractPlayer
var pos_manager: PositionManager
var layer


func init(player, l, p_m):
	layer = l
	pos_manager = p_m
	
	# This depends on the variables set above!
	set_player(player)


func set_player(player):
	pc_player = player
