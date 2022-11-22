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

var load_data_threaded := false
@onready var loading_thread = Thread.new()

const LOG_MODULE := "LAYERRENDERERS"

signal loading_started
signal loading_finished


func add_child(child: Node, force_readable_name: bool = false, internal: int = 0):
	if not position_manager and not apply_default_center:
		logger.debug("Adding child %s to %s, but not yet loading its data due to no available center position"
				% [child.name, name], LOG_MODULE)
		super.add_child(child, force_readable_name, internal)
		return
	
	# Give the child a center position
	if position_manager:
		# Apply the center position from the PositionManager
		child.position_manager = position_manager
		child.center = position_manager.get_center()
	elif apply_default_center:
		# Apply the default center for use without a PositionManager
		child.center = default_center
	
	# Actually add the child node to the tree
	super.add_child(child, force_readable_name, internal)
	
	# First full load is non-threaded
	child.full_load()
	child.apply_new_data()


# Apply a new center position to all child nodes
func apply_center(center_array):
	logger.debug("Applying new center center to all children in %s" % [name], LOG_MODULE)
	emit_signal("loading_started")
	
	renderers_finished = 0
	renderers_count = 0
	
	# Get the number of renderers first to avoid race conditions
	for renderer in get_children():
		if renderer is LayerCompositionRenderer:
			renderers_count += 1
	
	if load_data_threaded:
		loading_thread.start(Callable(self,"update_renderers").bind(center_array),
				Thread.PRIORITY_HIGH)
	else:
		update_renderers(center_array)


func update_renderers(center_array):
	# Now, load the data of each renderer
	for renderer in get_children():
		if renderer is LayerCompositionRenderer:
			renderer.center = center_array
			
			logger.debug("Child {} beginning to load", LOG_MODULE)

			renderer.full_load()
			call_deferred("_on_renderer_finished", renderer.name)
	
	call_deferred("finish_loading_thread")


func finish_loading_thread():
	loading_thread.wait_to_finish()


func get_debug_info():
	var info = ""
	
	for renderer in get_children():
		if renderer is LayerCompositionRenderer:
			info += String(renderer.name) + ": \n" + renderer.get_debug_info() + "\n\n"
	
	return info


func _on_renderer_finished(renderer_name):
	renderers_finished += 1
	
	logger.info(
		"Renderer %s of %s (with name %s) finished!" % [renderers_finished, renderers_count, renderer_name],
		LOG_MODULE
	)
	
	if renderers_finished == renderers_count:
		_apply_renderers_data()


# Called when all renderers are done loading data in a thread and ready to display it.
func _apply_renderers_data():
	for renderer in get_children():
		if renderer is LayerCompositionRenderer:
			renderer.apply_new_data()
	
	emit_signal("loading_finished")
