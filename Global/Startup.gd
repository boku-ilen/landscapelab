extends Node

# this provides the base directory of the LandscapeLab executable
var base_path: String = ""
# this provides the geopackage file for the whole landscapelab
var geopackage: String = ""


# this is the startup sequence and should be the first element
# of the auto loader configuration - no logging is available
func _ready():

	# preliminary set the window title
	OS.set_window_title("LandscapeLab!")

	# TODO: check the runtime parameters
	# var argv = OS.get_cmdline_args()

	# find the landscapelab geopackage
	base_path = OS.get_executable_path().get_base_dir()
	var base_dir = Directory.new()
	base_dir.open(base_path)
	base_dir.list_dir_begin()
	while true:
		var file = base_dir.get_next()
		if file == "":
			break
		elif file.begins_with("LL_") and (file.ends_with(".gpkg") or file.ends_with(".gpkgx")):
			geopackage = base_path + "/" + file
			break
	base_dir.list_dir_end()

	# if we could not find a geopackage we can not continue
	if geopackage == "":
		print("Could not find a valid geopackage! It has to be in the format of LL_<name>.gpkg[x]")
		get_tree().quit()

	# change the pixel transparency
	ProjectSettings.set_setting("display/window/per_pixel_transparency/enabled", false)
	ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", false)
	# start with maximized window with borders
	OS.set_window_maximized(true)
	OS.set_borderless_window(false)
	OS.set_window_always_on_top(false)
