extends Spatial


var position_manager: PositionManager setget set_position_manager, get_position_manager

# Used if no position manager is injected
export(bool) var apply_default_center = false
export(Array, int) var default_center = [0, 0]

var renderers_count = 0
var renderers_finished = 0

var load_data_threaded = true


func set_position_manager(new_manager: PositionManager):
	position_manager = new_manager
	position_manager.connect("new_center", self, "apply_center")
	
	apply_center(position_manager.get_center())


func get_position_manager() -> PositionManager:
	return position_manager


func add_child(child: Node, legible_unique_name: bool = false):
	if not position_manager and not apply_default_center:
		logger.info("Adding child %s to %s, but not yet loading its data due to no available center position"
				% [child.name, name])
		.add_child(child, legible_unique_name)
		return
	
	# Give the child a center position
	if position_manager:
		# Apply the center position from the PositionManager
		child.center = position_manager.get_center()
	elif apply_default_center:
		# Apply the default center for use without a PositionManager
		child.center = default_center
	
	# Start loading its data
	# FIXME: Start a thread with this
	child.load_new_data() # FIXME: Run in thread
	
	# Actually add the child node to the tree
	.add_child(child, legible_unique_name)
	
	# Apply the data
	# FIXME: Do this once all load_new_data threads are done!
	child.apply_new_data()


# Apply a new center position to all child nodes
func apply_center(center_array):
	logger.info("Applying new center center to all children in %s" % [name])
	
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
			
			var task = ThreadPool.Task.new(renderer, "load_new_data")
			
			if load_data_threaded:
				task.connect("finished", self, "_on_renderer_finished")
				ThreadPool.enqueue_task(task)
			else:
				task.execute()
				_on_renderer_finished()


func _on_renderer_finished():
	renderers_finished += 1
	
	logger.debug("Renderer %f of %f finished!" % [renderers_finished, renderers_count])
	
	if renderers_finished == renderers_count:
		_apply_renderers_data()


# Called when all renderers are done loading data in a thread and ready to display it.
func _apply_renderers_data():
	# Tell the position manager that loading is finished and this world shift is thus complete.
	# FIXME: This causes very tight coupling between the LayerRenderers node and the PositionManager.
	# We need to design this in a better way! One option to invert this dependency would be to register
	#  this as a dependent in the PositionManager
	position_manager.apply_new_position()
	
	for renderer in get_children():
		if renderer is LayerRenderer:
			renderer.apply_new_data()
