extends Viewport

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _init():
	debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	
	VisualServer.set_debug_generate_wireframes(true) # this