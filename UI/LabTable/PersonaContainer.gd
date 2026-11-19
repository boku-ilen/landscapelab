extends HBoxContainer


func _ready():
	create_personas_for_current_game_mode()
	GameSystem.game_mode_changed.connect(create_personas_for_current_game_mode)


func create_personas_for_current_game_mode():
	# Remove old personas
	for child in get_children():
		child.free()
	
	for persona in GameSystem.current_game_mode.game_personas.values():
		create_persona_ui(persona)


func create_persona_ui(persona: GamePersona):
	var persona_ui = preload("res://UI/LabTable/PersonaUI.tscn").instantiate()
	persona_ui.set_persona(persona)
	add_child(persona_ui)
