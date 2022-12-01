extends Node2D

@export var camera_path: NodePath
@onready var loading_thread = Thread.new()
var camera: Camera2D
var raster_renderer = preload("res://Layers/Renderers/GeoLayer/GeoRasterLayerRenderer.tscn")
var feature_renderer = preload("res://Layers/Renderers/GeoLayer/GeoFeatureLayerRenderer.tscn")

var renderers_finished := 0
var renderers_count := 0
var load_data_threaded := false

# Center in geocordinates
var center := Vector2.ZERO

const LOG_MODULE = "GEOLAYERRENDERERS"


func _ready():
	camera = get_node(camera_path)
	camera.offset_changed.connect(apply_offset)
		
	for layer in Layers.geo_layers["rasters"]:
		_instantiate_geolayer_renderer(layer, true)
	for layer in Layers.geo_layers["features"]:
		_instantiate_geolayer_renderer(layer, false)
	
	center = Vector2(Layers.current_center.x, Layers.current_center.z)
	apply_offset(Vector2(0,0), camera.get_viewport_rect().size, camera.zoom)
	
	#Layers.new_geo_layer.connect(_instantiate_geolayer_renderer)


func _instantiate_geolayer_renderer(geo_layer_name, is_raster: bool):
	var new_renderer
	if is_raster:
		if geo_layer_name == "ortho":
			new_renderer = raster_renderer.instantiate()
			new_renderer.geo_raster_layer = Layers.geo_layers["rasters"][geo_layer_name]
			new_renderer.z_index = 10
#	else: 
#		new_renderer = feature_renderer.instantiate()
#		camera.zoom_changed.connect(new_renderer.apply_zoom)
#		new_renderer.geo_feature_layer = Layers.geo_layers["features"][geo_layer_name]
#		new_renderer.z_index = 11
	
	if new_renderer:
		new_renderer.name = geo_layer_name
		add_child(new_renderer)


func apply_offset(offset, viewport_size, zoom):
	var current_center = center
	current_center.x += offset.x
	current_center.y -= offset.y
	logger.debug("Applying new center center to all children in %s" % [name], LOG_MODULE)
	emit_signal("loading_started")
	
	renderers_finished = 0
	renderers_count = 0  
	
	# Get the number of renderers first to avoid race conditions
	for renderer in get_children():
		if renderer is GeoLayerRenderer:
			renderers_count += 1
		
		if load_data_threaded:
			loading_thread.start(Callable(self,"update_renderers")
				.bind(current_center, viewport_size, zoom),Thread.PRIORITY_HIGH)
		else:
			update_renderers(current_center, offset, viewport_size, zoom)


func update_renderers(center, offset, viewport_size, zoom):
	# Now, load the data of each renderer
	for renderer in get_children():
		if renderer is GeoLayerRenderer:
			renderer.center = center
			renderer.viewport_size = viewport_size
			renderer.zoom = zoom
			renderer.position = offset
			
			logger.debug("Child {} beginning to load", LOG_MODULE)

			renderer.load_new_data()
			call_deferred("_on_renderer_finished", renderer.name)
	
	#call_deferred("finish_loading_thread")


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
