extends Object
class_name GameEvent


var title := ""
var description := ""
var triggers = []
var actions = []


func add_action(event_action: EventAction):
	actions.append(event_action)


func add_trigger(event_trigger: EventTrigger):
	event_trigger.triggered.connect(func(): apply_event(GameSystem.current_game_mode))
	triggers.append(event_trigger)


func apply_event(game_mode: GameMode):
	for action in actions:
		action.apply(game_mode)


func cleanup():
	for action in actions:
		action.cleanup()
