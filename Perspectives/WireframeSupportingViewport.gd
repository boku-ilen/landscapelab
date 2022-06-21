extends Viewport

#
# A viewport which makes sure that wireframes are generated, and shows them if the
# "wireframe_toggle" signal is emitted.
#


func _ready():
	# This line is required for wireframes to work.
	# See https://github.com/godotengine/godot/issues/15149
	VisualServer.set_debug_generate_wireframes(true)
	

# Emitted by e.g. the wireframe toggle - sets DEBUG_DRAW to Wireframe or Disabled.
func _on_wireframe_toggle(toggled):
	if toggled:
		debug_draw = DEBUG_DRAW_WIREFRAME
	else:
		debug_draw = DEBUG_DRAW_DISABLED


# TODO: Issue #48
func _unhandled_input(event):
	if event is InputEvent:
		pass
