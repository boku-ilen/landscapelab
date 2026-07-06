extends Node3D
class_name LayerCompositionRenderer

# Dependency comes from the LayerRenderers-Node which should always be above in the tree
var layer_composition: LayerComposition

var position_manager: PositionManager

# Offset to use as the center position
var center := [0, 0]

var last_load_position := Vector3.INF  # inf to provoke a first load

var current_task_id := -1

static var load_mutex := Mutex.new()

@export var load_refined_threaded := true
@export var load_adapt_threaded := true

# Time management
var time_manager: TimeManager :
	get:
		return time_manager
	set(manager):
		time_manager = manager
		time_manager.daytime_changed.connect(_apply_daytime_change)
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
	if current_task_id == -1 or WorkerThreadPool.is_task_completed(current_task_id):
		var diff = position_manager.center_node.position - last_load_position
		
		# FIXME: Display loading screen if diff is too large
		if is_new_loading_required(diff):
			if load_adapt_threaded:
				current_task_id = WorkerThreadPool.add_task(adapt_load.bind(diff))
			else:
				adapt_load(diff)
			last_load_position = position_manager.center_node.position
		else:
			if load_refined_threaded:
				current_task_id = WorkerThreadPool.add_task(refine_load)
			else:
				refine_load()


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
	# Workaround until we adapt to new multithreading system
	# See https://github.com/godotengine/godot/pull/78000
	if OS.get_thread_caller_id() != OS.get_main_thread_id():
		Thread.set_thread_safety_checks_enabled(false)


# Refine the currently loaded data, e.g. loading more detailed data near the camera.
# Run in a thread, so watch out for thread safety!
func refine_load():
	# Workaround until we adapt to new multithreading system
	# See https://github.com/godotengine/godot/pull/78000
	if OS.get_thread_caller_id() != OS.get_main_thread_id():
		Thread.set_thread_safety_checks_enabled(false)


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
