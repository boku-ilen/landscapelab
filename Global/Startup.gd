extends Node


# this is the startup sequence and should be the first element
# of the auto loader configuration - no logging is available?
func _ready():
	
	# start with maximized window
	OS.set_window_maximized(true)
