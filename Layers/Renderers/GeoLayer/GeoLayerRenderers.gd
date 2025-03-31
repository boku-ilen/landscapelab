extends Node2D

@export var camera: Camera2D
@export var load_data_threaded := true
@export var player_node: Node3D : 
	set(new_player):
		player_node = new_player
		$PlayerSprite.visible = new_player != null
var geo_transform: GeoTransform = GeoTransform.new()
var loading_threads = {}
var raster_renderer = preload("res://Layers/Renderers/GeoLayer/GeoRasterLayerRenderer.tscn")
var feature_renderer = preload("res://Layers/Renderers/GeoLayer/GeoFeatureLayerRenderer.tscn")
var crs_from
signal loading_finished
signal loading_started
signal camera_extent_changed(new_camera_extent)
signal popup_clicked

var renderers_finished := 0
var renderers_count := 0
var renderers_applied := 0

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
var center := -Vector2.INF : 
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


func _ready():
	geo_transform.set_transform(Layers.crs, 3857)
	
	for layer_def in Layers.layer_definitions.values():
		instantiate_geolayer_renderer(layer_def)
	
	Layers.new_layer_definition.connect(instantiate_geolayer_renderer)


func setup(geo_layer, initial_center, initial_crs_from):
	# Obtain metadata for correctly loading the full extent of the layer
	var extent = geo_layer.get_extent().size
	var zoom = Vector2(camera.get_viewport().size) / abs(extent)

	# Minimum of zoom vector -> the smaller the zoom the more will be rendered
	var zoom_factor = min(zoom.x, zoom.y)
	zoom = Vector2(zoom_factor, zoom_factor)
	
	camera.offset_changed.connect(apply_offset)
	
	center = initial_center
	apply_offset(Vector2.ZERO, camera.get_viewport_rect().size, camera.zoom)


func _process(delta):
	# Draw a player if defined
	if player_node != null:
		var player_pos_2d = Vector2(player_node.get_world_position().x, player_node.get_world_position().z)
		
		# Transform to according map projection in case they are different
		if geo_transform != null:
			var player_pos_transformed = geo_transform.transform_coordinates(player_node.get_world_position()) 
			player_pos_2d = Vector2(player_pos_transformed.x, player_pos_transformed.z) - center
			# Reverse coordinates to bring them into engine form
			player_pos_2d *= Vector2(1, -1)
		
		# Apply position and rotation to sprite
		$PlayerSprite.position = player_pos_2d + offset
		# For rotation, find the players forward and project it onto 2D space
		var player_forward = -player_node.get_node("Head/Camera3D").transform.basis.z
		var forward_2d = Plane.PLANE_XZ.project(player_forward)
		$PlayerSprite.rotation = forward_2d.signed_angle_to(Vector3.FORWARD, Vector3.UP)


func set_layer_visibility(layer_name: String, is_visible: bool, l_z_index := 0):
	get_node(layer_name).visible = true
	get_node(layer_name).z_index = l_z_index


func instantiate_geolayer_renderer(layer_definition: LayerDefinition):
	var renderer: GeoLayerRenderer
	var geo_layer: RefCounted = layer_definition.geo_layer
	if geo_layer is GeoRasterLayer:
		renderer = raster_renderer.instantiate()
		renderer.geo_raster_layer = geo_layer
	elif geo_layer is GeoFeatureLayer: 
		renderer = feature_renderer.instantiate()
		renderer.geo_feature_layer = geo_layer
		
		# Note: CONNECT_DEFERRED is needed to consistently react to all changes that
		#  happened within a given frame (e.g. when mass-deleting features).
		geo_layer.feature_added.connect(_on_feature_added.bind(renderer), CONNECT_DEFERRED)
		geo_layer.feature_removed.connect(_on_feature_removed.bind(renderer), CONNECT_DEFERRED)
		
		renderer.popup_clicked.connect(func(): popup_clicked.emit())
	else:
		logger.error("Invalid geolayer or geolayer name for {}"
						.format(geo_layer.name if geo_layer else "null layer"))
		return
	
	if renderer:
		renderer.layer_definition = layer_definition
		renderer.z_index = layer_definition.z_index
		
		if center == -Vector2.INF:
			var initial_center
			if player_node:
				var coords = geo_transform.transform_coordinates(
					player_node.get_true_position()
				)
				initial_center = Vector2(
					coords.x,
					coords.z
			)
			else:
				initial_center = Vector2(
				geo_layer.get_center().x,
					geo_layer.get_center().z
			)
			setup(geo_layer, initial_center, layer_definition.crs_from)
		
		loading_threads[renderer] = Thread.new()
		
		renderer.position = offset
		renderer.name = geo_layer.get_file_info()["name"]
		renderer.visibility_layer = visibility_layer
		layer_definition.visibility_changed.connect(func(is_visible): renderer.set_visible(is_visible))
		
		renderer.set_metadata(
			center,
			camera.get_viewport().size,
			camera.zoom,
			crs_from
		)
		
		add_child(renderer)
		renderers_count += 1
		renderer.refresh()
		renderers_finished += 1
		renderers_applied +=1


func apply_offset(new_offset, new_viewport_size, new_zoom):
	# Before setting any new metadata, we need to ensure data has been applied
	if renderers_applied != renderers_count:
		await loading_finished
	
	logger.debug("Applying new metadata to all children in %s" % [name])
	zoom = new_zoom
	offset += new_offset
	center.x += new_offset.x
	center.y -= new_offset.y
	
	loading_started.emit()
	
	# Start loading thread and load all geolayers in the thread
	renderers_finished = 0
	renderers_applied = 0
	
	if load_data_threaded:
		for renderer in get_children():
			if renderer is GeoLayerRenderer:
				if loading_threads[renderer].is_started() and not loading_threads[renderer].is_alive():
					loading_threads[renderer].wait_to_finish()
				
				loading_threads[renderer].start(update_renderer_with_new_data.bind(
					renderer, center, new_offset, new_viewport_size, new_zoom),
					Thread.PRIORITY_HIGH)
	else:
		for renderer in get_children():
			if renderer is GeoLayerRenderer:
				update_renderer_with_new_data(renderer, center, new_offset, new_viewport_size, new_zoom)


func update_renderer_with_new_data(renderer, new_center, new_offset, new_viewport_size, new_zoom):
	if load_data_threaded: Thread.set_thread_safety_checks_enabled(false)
	
	renderer.set_metadata(
		new_center,
		new_viewport_size,
		new_zoom,
		crs_from
	)
	
	renderer.load_new_data()
	_on_renderer_finished.call_deferred(renderer.name)


func _on_feature_added(feature, renderer):
	# FIXME: Keeping this would be preferable, but it causes reloads everytime an attribute is changed via slider.
	# We might need to differentiate between movement (which should be applied) and attribute changes (which should not)
	#feature.feature_changed.connect(_on_feature_changed.bind(renderer))
	update_renderer(renderer)


func _on_feature_removed(feature, renderer):
	update_renderer(renderer)


func _on_feature_changed(renderer):
	update_renderer(renderer)


func update_renderer_threaded(renderer):
	Thread.set_thread_safety_checks_enabled(false)
	renderer.load_new_data()
	renderer.apply_new_data.call_deferred()


func update_renderer(renderer):
	if load_data_threaded:
		if loading_threads[renderer].is_started() and not loading_threads[renderer].is_alive():
			loading_threads[renderer].wait_to_finish()
		
		if not loading_threads[renderer].is_started():
			loading_threads[renderer].start(update_renderer_threaded.bind(renderer), Thread.PRIORITY_NORMAL)
	else:
		renderer.load_new_data()
		renderer.apply_new_data()


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
			renderers_applied += 1
	
	loading_finished.emit()


func reclassify_z_indices(item_array):
	for item in item_array:
		if has_node(item.name):
			get_node(item.name).z_index = item.z_idx
