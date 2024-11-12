extends Node3D


var position_manager: PositionManager :
	get:
		return position_manager
	set(new_manager):
		position_manager = new_manager
		position_manager.connect("new_center",Callable(self,"apply_center"))
		
		position_manager.add_signal_dependency(self, "loading_finished")
		
		for renderer in get_children():
			if renderer is LayerCompositionRenderer:
				renderer.position_manager = position_manager
		
		apply_center(position_manager.get_center())

var time_manager: TimeManager :
	get:
		return time_manager 
	set(new_time_manager):
		time_manager = new_time_manager
		
		for renderer in get_children():
			renderer.set("time_manager", time_manager)

var weather_manager: WeatherManager :
	get:
		return weather_manager  
	set(new_weather_manager):
		weather_manager = new_weather_manager
		
		for renderer in get_children():
			renderer.set("weather_manager", weather_manager)

# Used if no position manager is injected
@export var apply_default_center: bool = false
@export var default_center = [0, 0] # (Array, int)

var renderers_count := 0
var renderers_finished := 0

signal loading_started
signal loading_finished


func add_composition(child: Node):
	if not position_manager and not apply_default_center:
		logger.debug("Adding child %s to %s, but not yet loading its data due to no available center position"
				% [child.name, name])
		add_child(child)
		return
	
	if weather_manager:
		child.set("weather_manager", weather_manager)
	
	# Give the child a center position
	if position_manager:
		# Apply the center position from the PositionManager
		child.position_manager = position_manager
		child.center = position_manager.get_center()
	elif apply_default_center:
		# Apply the default center for use without a PositionManager
		child.center = default_center
	
	if time_manager:
		child.time_manager = time_manager
	
	# Actually add the child node to the tree
	add_child(child)


# Apply a new center position to all child nodes
func apply_center(center_array):
	logger.info("Applying new center to all children in %s with center %s" % [name, str(center_array)])
	emit_signal("loading_started")
	
	renderers_finished = 0
	renderers_count = 0
	
	# Get the number of renderers first to avoid race conditions
	for renderer in get_children():
		if renderer is LayerCompositionRenderer:
			renderers_count += 1
	
	update_renderers(center_array)


func update_renderers(center_array):
	# Now, load the data of each renderer
	for renderer in get_children():
		if renderer is LayerCompositionRenderer:
			renderer.center = center_array
			
			logger.debug("Child {0} beginning to load".format([renderer.name]))

			renderer.full_load()
			call_deferred("_on_renderer_finished", renderer.name)


func get_debug_info():
	var info = ""
	
	for renderer in get_children():
		if renderer is LayerCompositionRenderer:
			info += String(renderer.name) + ": \n" + renderer.get_debug_info() + "\n\n"
	
	return info


func _on_renderer_finished(renderer_name):
	renderers_finished += 1
	
	logger.info(
		"Renderer %s of %s (with name %s) finished!" % [renderers_finished, renderers_count, renderer_name]
	)
	
	if renderers_finished == renderers_count:
		_apply_renderers_data()


# Called when all renderers are done loading data in a thread and ready to display it.
func _apply_renderers_data():
	for renderer in get_children():
		if renderer is LayerCompositionRenderer:
			renderer.apply_new_data()
	
	emit_signal("loading_finished")
