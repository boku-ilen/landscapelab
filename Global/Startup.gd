extends Node

# this provides the base directory of the LandscapeLab executable
var base_path: String = ""
# this provides the geopackage file for the whole landscapelab
var geopackage: String = ""


# this is the startup sequence and should be the first element
# of the auto loader configuration - no logging is available
func _ready():
	# preliminary set the window title
	# FIXME: Consider moving to the MainUI root - these may depend on which scene starts up
	#  (e.g. GeoPackage selection in a non-maximized window similar to the Godot project selection)
	OS.set_window_title("Landscape.Lab!")
	OS.set_window_maximized(true)
