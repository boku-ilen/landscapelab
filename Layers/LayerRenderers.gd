extends Spatial


var position_manager: PositionManager setget set_position_manager, get_position_manager

# Used if no position manager is injected
export(bool) var apply_default_center = false
export(Array, int) var default_center = [0, 0]


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
	
	for renderer in get_children():
		if renderer is LayerRenderer:
			renderer.center = center_array
			renderer.load_new_data() # FIXME: Run in a thread
	
	# FIXME: Do after all data loading is done
	for renderer in get_children():
		if renderer is LayerRenderer:
			renderer.apply_new_data()
