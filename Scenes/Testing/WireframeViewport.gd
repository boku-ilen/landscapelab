extends Viewport

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	VisualServer.set_debug_generate_wireframes(true) # this
	debug_draw = Viewport.DEBUG_DRAW_DISABLED # disable wireframes at the start

func _input(event):
	# Toggle wireframe mode or normal mode
	if event.is_action_pressed("toggle_wireframe"):
		if debug_draw == Viewport.DEBUG_DRAW_DISABLED: # If debug draw is currently off, change to wireframe
			logger.info("Turning wireframes on")
			debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
		else: # Else (if there currently is a debug draw mode turned on), change to normal
			logger.info("Turning wireframes off")
			debug_draw = Viewport.DEBUG_DRAW_DISABLED