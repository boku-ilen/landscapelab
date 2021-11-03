extends Spatial


var position_manager: PositionManager setget set_position_manager, get_position_manager
var time_manager: TimeManager setget set_time_manager
var weather_manager: WeatherManager setget set_weather_manager

# Used if no position manager is injected
export(bool) var apply_default_center = false
export(Array, int) var default_center = [0, 0]

var renderers_count := 0
var renderers_finished := 0

var load_data_threaded := true

signal loading_started
signal loading_finished


func set_position_manager(new_manager: PositionManager):
	position_manager = new_manager
	position_manager.connect("new_center", self, "apply_center")
	
	position_manager.add_signal_dependency(self, "loading_finished")
	
	apply_center(position_manager.get_center())


func get_position_manager() -> PositionManager:
	return position_manager


func set_time_manager(new_time_manager):
	time_manager = new_time_manager
	
	for renderer in get_children():
		renderer.set("time_manager", time_manager)


func set_weather_manager(new_weather_manager):
	weather_manager = new_weather_manager
	
	for renderer in get_children():
		renderer.set("weather_manager", weather_manager)


func add_child(child: Node, legible_unique_name: bool = false):
	if not position_manager and not apply_default_center:
		logger.debug("Adding child %s to %s, but not yet loading its data due to no available center position"
				% [child.name, name], "render")
		.add_child(child, legible_unique_name)
		return
	
	# Give the child a center position
	if position_manager:
		# Apply the center position from the PositionManager
		child.center = position_manager.get_center()
	elif apply_default_center:
		# Apply the default center for use without a PositionManager
		child.center = default_center
	
	# Actually add the child node to the tree
	.add_child(child, legible_unique_name)
	
	# Start loading its data
	# FIXME: Start a thread with this
	child.load_new_data() # FIXME: Run in thread
	
	# Apply the data
	# FIXME: Do this once all load_new_data threads are done!
	child.apply_new_data()


# Apply a new center position to all child nodes
func apply_center(center_array):
	logger.debug("Applying new center center to all children in %s" % [name], "render")
	emit_signal("loading_started")
	
	renderers_finished = 0
	renderers_count = 0
	
	# Get the number of renderers first to avoid race conditions
	for renderer in get_children():
		if renderer is LayerRenderer:
			renderers_count += 1
	
	# Now, load the data of each renderer
	for renderer in get_children():
		if renderer is LayerRenderer:
			renderer.center = center_array
			
			logger.debug("Child {} beginning to load", "render")
			var task = ThreadPool.Task.new(renderer, "load_new_data")
			
			if load_data_threaded:
				task.connect("finished", self, "_on_renderer_finished", [renderer.name])
				ThreadPool.enqueue_task(task)
			else:
				task.execute()
				_on_renderer_finished(renderer.name)


func _on_renderer_finished(renderer_name):
	renderers_finished += 1
	
	logger.debug(
		"Renderer %s of %s (with name %s) finished!" % [renderers_finished, renderers_count, renderer_name],
		"render"
	)
	
	if renderers_finished == renderers_count:
		_apply_renderers_data()


# Called when all renderers are done loading data in a thread and ready to display it.
func _apply_renderers_data():
	for renderer in get_children():
		if renderer is LayerRenderer:
			renderer.apply_new_data()
	
	emit_signal("loading_finished")
