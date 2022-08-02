extends GameMode
class_name TurnBasedGameMode


var events_per_turn = {}  # Dictionary of dictionaries of events
var constant_events = {}

var current_turn_number := 0
var total_turn_number := 5

var finished = false


signal new_turn_beginning
signal turn_ending
signal game_finished
signal event_occurring(event)


func add_event_at_turn(event: GameEvent, turn: int):
	if not events_per_turn.has(turn): events_per_turn[turn] = {}
	
	events_per_turn[turn][event.title] = event


func add_constant_event(event: GameEvent):
	constant_events[event.title] = event


func next_turn():
	if not finished:
		_resolve_turn()


func _apply_event(event: GameEvent):
	emit_signal("event_occurring", event)
	event.apply_event(self)


func _finish_game():
	finished = true
	emit_signal("game_finished")


func _setup_turn():
	emit_signal("new_turn_beginning")


func _resolve_turn():
	# Move on to next phase
	if current_turn_number + 1 < total_turn_number:
		emit_signal("turn_ending")
	
		# Apply constant events
		for event in constant_events.values():
			_apply_event(event)
		
		# Apply events specific to this turn
		if events_per_turn.has(current_turn_number):
			for event in events_per_turn[current_turn_number].values():
				_apply_event(event)
		
		current_turn_number += 1
		_setup_turn()
	else:
		_finish_game()
