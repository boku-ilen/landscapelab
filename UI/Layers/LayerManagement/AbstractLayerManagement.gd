extends Node
class_name AbstractLayerManagement

# FIXME: Move from LayerCompositions to GeoLayers


var pc_player: AbstractPlayer
var pos_manager: PositionManager
var layerc: LayerComposition


func init(player, lc, p_m):
	layerc = lc
	pos_manager = p_m
	
	# This depends checked the variables set above!
	set_player(player)


func set_player(player):
	pc_player = player
