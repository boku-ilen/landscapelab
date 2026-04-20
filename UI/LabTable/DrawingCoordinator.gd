extends Node
class_name DrawingCoordinator

@export var viewport_camera: Viewport2DCamera

var fixed_lids: Array

var last_camera_extent: GeoLayerRenderers.CameraExtent
var fixed_last_extent: GeoLayerRenderers.CameraExtent
var freeze := false

func _ready():
	await RenderingServer.frame_post_draw
	get_parent().geo_layer_renderers.camera_extent_changed.connect(
		func (new_extent):
			if not freeze:
				last_camera_extent = new_extent
	)

func start_drawing():
	fixed_last_extent = last_camera_extent
	for n in get_tree().get_nodes_in_group("RegularUI"):
		if n is CanvasItem:
			n.visible = false
	for n in get_tree().get_nodes_in_group("DrawingUI"):
		if n is CanvasItem:
			n.visible = true

func start_capture():
	$TextureRect.visible = true
	await RenderingServer.frame_post_draw
	get_parent().communicator.request_drawing_capture()

func _transform_point(screen_position):
	var global_position = viewport_camera.screen_to_global(screen_position)
	var vector_3857 = Vector3(
				global_position.x - get_parent().geo_layers.offset.x + get_parent().geo_layers.center.x,
				0,
				-global_position.y + get_parent().geo_layers.offset.y + get_parent().geo_layers.center.y)
		
	var vector_local = get_parent().geo_transform.transform_coordinates(vector_3857)
	vector_local.z = -vector_local.z
	return vector_local


func handle_returned_drawing(layer_index, position, scale, resolution, bounds, binary_data):
	$TextureRect.visible = false
	get_parent().geo_layer_renderers.set_layer_visibility("MASKS", true)
	for n in get_tree().get_nodes_in_group("RegularUI"):
		if n is CanvasItem:
			n.visible = true
	for n in get_tree().get_nodes_in_group("DrawingUI"):
		if n is CanvasItem:
			n.visible = false
			
	var real_position = Vector2(DisplayServer.window_get_size(get_viewport().get_window().get_window_id())) * position
	var local_position = _transform_point(real_position)
	
	var full_width_right = Vector2(DisplayServer.window_get_size(get_viewport().get_window().get_window_id())) * (position + Vector2((bounds[2]) * 10, 0))
	var local_full_width = _transform_point(full_width_right)
	#var realPosition = fixed_last_extent.center + fixed_last_extent.extent * (position - Vector2(0.5, 0.5))
	
	
	#realPosition = viewport_camera.screen_to_global(realPosition)
	logger.info(str(layer_index))
	var feature = Layers.get_layer_composition("Masks Placeholder").render_info.get_geolayers()[1].create_feature()
	
	feature.set_vector3(local_position)
	feature.set_attribute("lid", str(fixed_lids[layer_index]))
	feature.set_attribute("width", str(resolution[0]))
	feature.set_attribute("height", str(resolution[1]))
	feature.set_attribute("meters_per_pixel", str(((local_full_width - local_position).x * 0.1) / resolution[0]))
	feature.set_binary_attribute("image", binary_data)
	logger.info(str(scale))
