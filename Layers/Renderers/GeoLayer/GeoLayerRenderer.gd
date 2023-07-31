extends Node2D
class_name GeoLayerRenderer


# Offset to use as the center position
var center := Vector2.ZERO
var viewport_size := Vector2.ONE * 100
var zoom := Vector2.ONE
var radius := 1000


# Overload with the functionality to load new data, but not use (visualize) it yet. Run in a thread,
#  so watch out for thread safety!
func load_new_data():
	pass


# Overload to return a string with statistics and information about the current state of this
# renderer
func get_debug_info() -> String:
	return ""


# Overload with applying and visualizing the data. Not run in a thread.
func apply_new_data():
	pass


# Reload the data within this layer
# Not threaded! Should only be called as a response to user input, otherwise use load_new_data and
# apply_new_data threaded as intended
func refresh():
	load_new_data()
	apply_new_data()
