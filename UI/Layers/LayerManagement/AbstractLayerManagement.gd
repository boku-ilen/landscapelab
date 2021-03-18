extends Node
class_name AbstractLayerManagement


var pc_player: AbstractPlayer
var pos_manager: PositionManager
var layer


func init(player, l):
	layer = l
	set_player(player)


func set_player(player):
	pc_player = player
