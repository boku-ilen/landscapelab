extends Object
class_name GameEvent


var title := ""
var description := ""
var actions = []


func add_action(event_action: EventAction):
	actions.append(event_action)


func apply_event(game_mode: GameMode):
	for action in actions:
		action.apply(game_mode)


func cleanup():
	for action in actions:
		action.cleanup()
