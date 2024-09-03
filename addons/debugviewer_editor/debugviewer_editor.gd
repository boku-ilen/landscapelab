@tool
extends EditorPlugin

# Overrides input so DebugViewer can handle keypresses in editor

func _unhandled_input(event):
	get_editor_interface().get_edited_scene_root().propagate_call("_input", [event])

func _enter_tree():
	# Initialization of the plugin goes here.
	pass

func _exit_tree():
	# Clean-up of the plugin goes here.
	pass
