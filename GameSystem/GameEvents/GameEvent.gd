extends Object
class_name GameEvent


var title := ""
var description := ""


# To be implemented by inheriting classes
func apply_event(game_mode: GameMode):
	pass
