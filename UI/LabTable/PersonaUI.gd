extends TableButton


var persona: GamePersona

func set_persona(initial_persona) -> void:
	persona = initial_persona
	
	pressed.connect(switch_visibility)
	
	if is_inside_tree(): set_persona_info()


func _ready():
	set_persona_info()


func speak(message):
	$PersonaContent/VBoxContainer/SpeakLabel.text = message
	popup()


func switch_visibility():
	if $PersonaContent.visible: popdown()
	else: popup()


func set_persona_info():
	if persona:
		$PersonaContent/VBoxContainer/NameLabel.text = persona.name
		$PersonaContent/VBoxContainer/SpeakLabel.text = persona.description
		icon = persona.icon


func popup():
	$PersonaContent.visible = true


func popdown():
	$PersonaContent.visible = false
