extends Node2D


@onready var loading_thread = Thread.new()
var raster_renderer = preload("res://Layers/Renderers/GeoLayer/GeoRasterLayerRenderer.tscn")
var feature_renderer = preload("res://Layers/Renderers/GeoLayer/GeoFeatureLayerRenderer.tscn")

var pos_manager: PositionManager :
	get:
		return pos_manager
	set(new_manager):
		pos_manager = new_manager
		pos_manager.connect("new_center",Callable(self,"apply_center"))
		
		pos_manager.add_signal_dependency(self, "loading_finished")
		
		apply_center(pos_manager.get_center())

var renderers_finished := 0
var renderers_count := 0
var load_data_threaded := false

const LOG_MODULE = "GEOLAYERRENDERERS"

func _ready():
	for layer in Layers.geo_layers["rasters"]:
		_instantiate_geolayer_renderer(layer, true)
	for layer in Layers.geo_layers["features"]:
		_instantiate_geolayer_renderer(layer, false)
	
	Layers.new_geo_layer.connect(_instantiate_geolayer_renderer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _instantiate_geolayer_renderer(geo_layer_name, is_raster: bool):
	var new_renderer
	if is_raster:
		new_renderer = raster_renderer.instantiate()
		new_renderer.geo_raster_layer = Layers.geo_layers["rasters"][geo_layer_name]
	else:
		new_renderer = feature_renderer.instantiate()
		new_renderer.geo_feature_layer = Layers.geo_layers["features"][geo_layer_name]
	
	new_renderer.name = geo_layer_name
	add_child(new_renderer)


# Apply a new center position to all child nodes
func apply_center(center_array):
	logger.debug("Applying new center center to all children in %s" % [name], LOG_MODULE)
	emit_signal("loading_started")
	
	renderers_finished = 0
	renderers_count = 0
	
	# Get the number of renderers first to avoid race conditions
	for renderer in get_children():
		if renderer is GeoLayerRenderer:
			renderers_count += 1
	
#	if load_data_threaded:
#		loading_thread.start(Callable(self,"update_renderers").bind(center_array),
#				Thread.PRIORITY_HIGH)
#	else:
	update_renderers(center_array)


func update_renderers(center_array):
	# Now, load the data of each renderer
	for renderer in get_children():
		if renderer is GeoLayerRenderer:
			renderer.center = center_array
			
			logger.debug("Child {} beginning to load", LOG_MODULE)

			renderer.load_new_data()
			call_deferred("_on_renderer_finished", renderer.name)
	
	call_deferred("finish_loading_thread")



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
		if renderer is GeoLayerRenderer:
			renderer.apply_new_data()
	
	emit_signal("loading_finished")
