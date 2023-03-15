extends Node3D
class_name LayerCompositionRenderer


# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer_composition: LayerComposition

var position_manager: PositionManager

# Offset to use as the center position
var center := [0, 0]

var last_load_position := Vector3.ZERO

var loading_thread := Thread.new()

# Time management
var time_manager: TimeManager :
	get:
		return time_manager
	set(manager):
		time_manager = manager
		time_manager.connect("daytime_changed",Callable(self,"_apply_daytime_change"))
		set_time_manager()

var is_daytime = true


# To be implemented by child class
func set_time_manager():
	pass


func _ready():
	layer_composition.connect("visibility_changed",Callable(self,"set_visible"))
	layer_composition.connect("refresh_view",Callable(self,"refresh"))


# Generic layer loading logic: if the loading thread is free, adapt the data to the current position
# or refine the current data if the position has not changed much.
# Do not override (remember to call call `super._process(delta)` if overloading)!
func _process(_delta):
	if loading_thread.is_started() and not loading_thread.is_alive():
		loading_thread.wait_to_finish()
	
	if not loading_thread.is_started():
		var diff = position_manager.center_node.position - last_load_position
		if is_new_loading_required(diff):
			loading_thread.start(adapt_load.bind(diff))
#			adapt_load(diff)
			last_load_position = position_manager.center_node.position
		else:
			loading_thread.start(refine_load)


# Overload with a check which returns `true` if new data loading is required, e.g. because the
#  camera distance since the last loading is too high 
func is_new_loading_required(_position_diff: Vector3) -> bool:
	return false


# Reset and fully load new data for the new world-shifted origin.
# Run in a thread, so watch out for thread safety!
func full_load():
	pass


# Adapt the current data based on the given position_diff, loading new data where required.
# Likely implemented similarly to full_load, but re-using existing data where possible.
# Run in a thread, so watch out for thread safety!
func adapt_load(_position_diff: Vector3):
	pass


# Refine the currently loaded data, e.g. loading more detailed data near the camera.
# Run in a thread, so watch out for thread safety!
func refine_load():
	pass


# Overload to return a string with statistics and information about the current state of this
# renderer
func get_debug_info() -> String:
	return ""


# Overload with applying and visualizing the data. Not run in a thread.
func apply_new_data():
	_apply_daytime_change(is_daytime)


# Reload the data within this layer
# Not threaded! Should only be called as a response to user input, otherwise use full_load and
# apply_new_data threaded as intended
func refresh():
	full_load()
	apply_new_data()


# Emitted from the injected time_manager
func _apply_daytime_change(daytime: bool):
	is_daytime = daytime
	
	for child in get_children():
		if child.has_method("apply_daytime_change"):
			child.apply_daytime_change(daytime)
