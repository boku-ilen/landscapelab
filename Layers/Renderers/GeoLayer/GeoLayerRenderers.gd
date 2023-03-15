extends Node2D

@export var camera_path: NodePath
@onready var loading_thread = Thread.new()
var camera: Camera2D
var raster_renderer = preload("res://Layers/Renderers/GeoLayer/GeoRasterLayerRenderer.tscn")
var feature_renderer = preload("res://Layers/Renderers/GeoLayer/GeoFeatureLayerRenderer.tscn")
signal loading_finished
signal loading_started

var renderers_finished := 0
var renderers_count := 0
var load_data_threaded := true

# Center in geocordinates
var center := Vector2.ZERO
var offset := Vector2.ZERO
var zoom := Vector2.ONE


func _ready():
	camera = get_node(camera_path)
	camera.offset_changed.connect(apply_offset)
		
	for layer in Layers.geo_layers["rasters"].values():
		_instantiate_geolayer_renderer(layer)
	for layer in Layers.geo_layers["features"].values():
		_instantiate_geolayer_renderer(layer)
	
	center = Vector2(Layers.current_center.x, Layers.current_center.z)
	apply_offset(Vector2.ZERO, camera.get_viewport_rect().size, camera.zoom)
	
	#Layers.new_geo_layer.connect(_instantiate_geolayer_renderer)


func _instantiate_geolayer_renderer(geo_layer: Resource):
	var new_renderer
	if geo_layer is GeoRasterLayer:
		new_renderer = raster_renderer.instantiate()
		new_renderer.geo_raster_layer = geo_layer
	else: 
		new_renderer = feature_renderer.instantiate()
		new_renderer.geo_feature_layer = geo_layer
	
	if new_renderer:
		new_renderer.name = geo_layer.resource_name
		add_child(new_renderer)


func apply_offset(offset, viewport_size, zoom):
	self.zoom = zoom
	self.offset = offset
	var current_center = center
	current_center.x += offset.x
	current_center.y -= offset.y
	logger.debug("Applying new center center to all children in %s" % [name])
	emit_signal("loading_started")
	
	renderers_finished = 0
	renderers_count = 0  
	
	# Get the number of renderers first to avoid race conditions
	renderers_count = get_children() \
		.filter(func(renderer): return renderer is GeoLayerRenderer).size()
	
	# Start loading thread and load all geolayers in the thread
	if load_data_threaded:
		if loading_thread.is_started() and not loading_thread.is_alive():
			loading_thread.wait_to_finish()
		
		if not loading_thread.is_started():
			loading_thread.start(update_renderers.bind(
				current_center, offset, viewport_size, zoom), Thread.PRIORITY_NORMAL)
	else:
		update_renderers(current_center, offset, viewport_size, zoom)


func update_renderers(center, offset, viewport_size, zoom):
	# The maximum radius is at the corners => get the diagonale divided by 2s
	var radius = sqrt(pow(viewport_size.x / zoom.x, 2) + pow(viewport_size.y / zoom.y, 2)) / 2
	# Now, load the data of each renderer
	for renderer in get_children():
		if renderer is GeoLayerRenderer:
			renderer.center = center
			renderer.viewport_size = viewport_size
			renderer.zoom = zoom
			renderer.radius = radius

			renderer.load_new_data()
			_on_renderer_finished.call_deferred(renderer.name)


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
		if renderer is GeoLayerRenderer:
			renderer.apply_new_data()
			# Only apply the position after the new data has
			# been applied otherwise it will look clunky
			renderer.position = offset
	
	emit_signal("loading_finished")


func reclassify_z_indices(item_array):
	for item in item_array:
		if has_node(item.name):
			get_node(item.name).z_index = item.z_idx
