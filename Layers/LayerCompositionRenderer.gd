extends Node3D
class_name LayerCompositionRenderer


# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer_composition: LayerComposition

# Offset to use as the center position
var center := [0, 0]

# Time management
var time_manager: TimeManager :
	get:
		return time_manager
	set(manager):
		time_manager = manager
		time_manager.connect("daytime_changed",Callable(self,"_apply_daytime_change"))
		set_time_manager()

var is_daytime = true

const LOG_MODULE := "LAYERRENDERERS"


# To be implemented by child class
func set_time_manager():
	pass


func _ready():
	layer_composition.connect("visibility_changed",Callable(self,"set_visible"))
	layer_composition.connect("refresh_view",Callable(self,"refresh"))


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
	_apply_daytime_change(is_daytime)


# Reload the data within this layer
# Not threaded! Should only be called as a response to user input, otherwise use load_new_data and
# apply_new_data threaded as intended
func refresh():
	load_new_data()
	apply_new_data()


# Emitted from the injected time_manager
func _apply_daytime_change(daytime: bool):
	is_daytime = daytime
	
	for child in get_children():
		if child.has_method("apply_daytime_change"):
			child.apply_daytime_change(daytime)
