extends Node3D
class_name LayerRenderer


# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer: Layer

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

const LOG_MODULE := "LAYERRENDERERS"


# To be implemented by child class
func set_time_manager():
	pass


func _ready():
	layer.connect("visibility_changed",Callable(self,"set_visible"))
	layer.connect("refresh_view",Callable(self,"refresh"))


func _process(delta):
	if loading_thread.is_started() and not loading_thread.is_alive():
		loading_thread.wait_to_finish()
	
	if not loading_thread.is_started():
		var diff = position_manager.center_node.position - last_load_position
		if is_new_loading_required(diff):
#			loading_thread.start(load_new_data.bind(diff))
			load_new_data(diff)
			last_load_position = position_manager.center_node.position
		else:
			loading_thread.start(load_refined_data)


# Overload with a check which returns `true` if new data loading is required, e.g. because the
#  camera distance since the last loading is too high 
func is_new_loading_required(position_diff: Vector3) -> bool:
	return false


# Overload with the functionality to load new data, but not use (visualize) it yet. Run in a thread,
#  so watch out for thread safety!
func load_new_data(position_diff: Vector3):
	pass


# Overload with functionality to refine the data for the current position
func load_refined_data():
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
	load_new_data(Vector3.ZERO)
	apply_new_data()


# Emitted from the injected time_manager
func _apply_daytime_change(daytime: bool):
	is_daytime = daytime
	
	for child in get_children():
		if child.has_method("apply_daytime_change"):
			child.apply_daytime_change(daytime)
