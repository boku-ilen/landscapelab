extends Node2D

@export var camera: Camera2D
@export var load_data_threaded := true

var loading_thread := Thread.new() 
var raster_renderer = preload("res://Layers/Renderers/GeoLayer/GeoRasterLayerRenderer.tscn")
var feature_renderer = preload("res://Layers/Renderers/GeoLayer/GeoFeatureLayerRenderer.tscn")
signal loading_finished
signal loading_started
signal camera_extent_changed(new_camera_extent)

var renderers_finished := 0
var renderers_count := 0

class CameraExtent:
	func _init(c: Vector2, e: Vector2):
		center = c
		extent = e
	
	var center: Vector2
	var extent: Vector2

# Center in geo-coordinates
var camera_extent := CameraExtent.new(Vector2.ZERO, Vector2.ZERO) : 
	set(new_camera_extent):
		camera_extent = new_camera_extent
		camera_extent_changed.emit(new_camera_extent)
var center := Vector2.ZERO : 
	set(new_center):
		center = new_center
var zoom := Vector2.ONE : 
	set(new_zoom):
		zoom = new_zoom
		camera_extent.extent = camera.get_viewport_rect().size / zoom
		camera_extent_changed.emit(camera_extent)
var offset := Vector2.ZERO :
	set(new_offset):
		offset = new_offset
		camera_extent.center = offset
		camera_extent_changed.emit(camera_extent)


func _ready(): setup()


func setup():
	camera.offset_changed.connect(apply_offset)
	
	center = Vector2(Layers.current_center.x, Layers.current_center.z)
	apply_offset(Vector2.ZERO, camera.get_viewport_rect().size, camera.zoom)


func set_layer_visibility(layer_name: String, is_visible: bool):
	# geolayers shall not be instantiated by default only on user's wish
	if not has_node(layer_name):
		instantiate_geolayer_renderer(layer_name)
	
	get_node(layer_name).visible = true


func instantiate_geolayer_renderer(layer_name: String):
	var geo_layer = Layers.get_geo_layer_by_name(layer_name)
	var renderer
	if geo_layer is GeoRasterLayer:
		renderer = raster_renderer.instantiate()
		renderer.geo_raster_layer = geo_layer
	elif geo_layer is GeoFeatureLayer: 
		renderer = feature_renderer.instantiate()
		renderer.geo_feature_layer = geo_layer
	else:
		logger.error("Invalid geolayer or geolayer name for {}"
						.format(geo_layer.name))
		return
	
	if renderer:
		renderer.position = offset
		renderer.name = geo_layer.get_file_info()["name"]
		renderer.visibility_layer = visibility_layer
		
		renderer.set_metadata(
			center,
			camera.get_viewport().size,
			camera.zoom
		)
		add_child(renderer)
		renderer.refresh()


func apply_offset(new_offset, new_viewport_size, new_zoom):
	zoom = new_zoom
	offset += new_offset
	center.x += new_offset.x
	center.y -= new_offset.y
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
				center, new_offset, new_viewport_size, new_zoom), Thread.PRIORITY_NORMAL)
	else:
		update_renderers(center, new_offset, new_viewport_size, new_zoom)


func update_renderers(new_center, new_offset, new_viewport_size, new_zoom):
	Thread.set_thread_safety_checks_enabled(false)
	# Now, load the data of each renderer
	for renderer in get_children():
		if renderer is GeoLayerRenderer:
			renderer.set_metadata(
				new_center,
				new_viewport_size,
				new_zoom
			)
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
