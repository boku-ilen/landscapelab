extends HBoxContainer

var previous_frame_speaks = {}
var previously_spoken_statements = {}
var persona_to_ui = {}

const SPEAK_PROBABILITY = 0.5


func _ready():
	create_personas_for_current_game_mode()
	GameSystem.game_mode_changed.connect(create_personas_for_current_game_mode)


func _process(_delta: float) -> void:
	# First, choose a random persona from all personas who have spoken in the previous frame.
	# This gives all personas an equal weight, as opposed to those with more potential statements
	#  having a higher probability of being chosen.
	var previous_frame_personas = []
	
	for persona in previous_frame_speaks.keys():
		if previous_frame_speaks[persona].size() > 0: previous_frame_personas.append(persona)
	
	if previous_frame_personas.size() == 0: return
	var persona = previous_frame_personas[randi_range(0, previous_frame_personas.size() - 1)]
	
	var num_messages = previous_frame_speaks[persona].size()
	
	# Initial gate: should we speak at all?
	if randf_range(0.0, 1.0) > SPEAK_PROBABILITY:
		clear_messages()
		return
	
	# Second gate: which message to speak?
	var message_index = randi_range(0, num_messages - 1)
	var message = previous_frame_speaks[persona][message_index]
	
	persona_to_ui[persona].speak(message)
	previously_spoken_statements[message] = true
	
	# Only one persona speaks per frame -> delete the rest
	clear_messages()


func clear_messages():
	for persona in previous_frame_speaks.keys():
		previous_frame_speaks[persona] = []


func create_personas_for_current_game_mode():
	# Remove old personas
	for child in get_children():
		child.free()
	
	for persona in GameSystem.current_game_mode.game_personas.values():
		create_persona_ui(persona)


func create_persona_ui(persona: GamePersona):
	var persona_ui = preload("res://UI/LabTable/PersonaUI.tscn").instantiate()
	persona_ui.set_persona(persona)
	persona.spoke.connect(_on_persona_spoke.bind(persona), CONNECT_DEFERRED)
	persona_to_ui[persona] = persona_ui
	add_child(persona_ui)


func _on_persona_spoke(message: String, persona: GamePersona):
	# Don't speak a message twice per game
	if message in previously_spoken_statements: return
	
	if not persona in previous_frame_speaks:
		previous_frame_speaks[persona] = [message]
	else:
		previous_frame_speaks[persona].append(message)
