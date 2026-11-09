extends EventAction

var persona: GamePersona
var text: String


func apply(_game_mode: GameMode):
	persona.speak(text)
