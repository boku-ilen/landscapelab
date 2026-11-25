extends EventAction
class_name PersonaSpeakAction

var persona: GamePersona
var text: String


func _init(initial_name, initial_persona: GamePersona, initial_text: String = ""):
	name = initial_name
	persona = initial_persona
	text = initial_text


func apply(_game_mode: GameMode):
	if persona == null:
		logger.warn("PersonaSpeakAction %s has no persona set, cannot speak: %s" % [name, text])
		return
	persona.speak(text)
