extends GameEvent
class_name RandomGameEvent


var events := []
var current_random_event: GameEvent


func add_event(event):
	events.append(event)
	prepare_new_random_event()


func prepare_new_random_event():
	var random_event_index = randi() % events.size()
	current_random_event = events[random_event_index]
	
	title = current_random_event.title
	description = current_random_event.description


# To be implemented by inheriting classes
func apply_event(game_mode: GameMode):
	current_random_event.apply_event(game_mode)


func cleanup():
	prepare_new_random_event()
