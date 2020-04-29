extends Node

#
# Root node / container for game states.
# 
# emit_completed() should be triggered by a child node when the state should
# terminate and switch to the next state.
# 
# Currently only one next state is supported, but this could easily be extended
# by passing a parameter to emit_completed() / having multiple next_state_paths.
#


export(String, FILE, "*.tscn") var next_state_path


signal completed(next_state)


func emit_completed():
	emit_signal("completed", next_state_path)
