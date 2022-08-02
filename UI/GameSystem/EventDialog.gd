extends AcceptDialog


var events_waiting := 0


func _ready():
	GameSystem.current_game_mode.connect("event_occurring", self, "_on_event_occurring")


func _on_event_occurring(event: GameEvent):
	# If we're already displaying an event, wait for it to be acknowledged
	if visible:
		events_waiting += 1
		
		for i in range(events_waiting):
			yield(self, "confirmed")
		
		events_waiting -= 1
	
	window_title = event.title
	dialog_text = event.description
	popup_centered()
