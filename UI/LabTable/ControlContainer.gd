extends VBoxContainer


signal recenter(center)

@export var shift_relative_x := 0.3
@export var shift_relative_y := 0.3
@export var camera_2d: Camera2D : 
	set(new_camera_2d):
		camera_2d = new_camera_2d
		zoom_container.camera_2d = new_camera_2d
		
		# Shift relative to the current viewport size on button clicks
		right.pressed.connect(func():
			var shift_abs = (Vector2(camera_2d.get_viewport().size) / camera_2d.zoom).x * shift_relative_x
			camera_2d.add_offset_and_emit(Vector2(shift_abs, 0)))
		left.pressed.connect(func():
			var shift_abs = (Vector2(camera_2d.get_viewport().size) / camera_2d.zoom).x * shift_relative_x
			camera_2d.add_offset_and_emit(Vector2(-shift_abs, 0)))
		up.pressed.connect(func():
			var shift_abs = (Vector2(camera_2d.get_viewport().size) / camera_2d.zoom).y * shift_relative_y
			camera_2d.add_offset_and_emit(Vector2(0, -shift_abs)))
		down.pressed.connect(func():
			var shift_abs = (Vector2(camera_2d.get_viewport().size) / camera_2d.zoom).y * shift_relative_y
			camera_2d.add_offset_and_emit(Vector2(0, shift_abs)))
		center.pressed.connect(func():
			camera_2d.set_offset_and_emit(Vector2.ZERO))
@export var overview_camera: Camera2D

@export_group("Control Nodes")
@export var visibility_button: Button
@export var zoom_container: Container
@export var grid_container: Container
@export var subviewport_container: Container
@export_subgroup("Shift Controls")
@export var left: Button
@export var right: Button
@export var up: Button
@export var down: Button
@export var center: Button


func _ready():
	visibility_button.toggled.connect(func(toggled):
		for control in [zoom_container, grid_container, subviewport_container]:
			control.visible = !toggled
		visibility_button.texture_name = "m_open" if toggled else "m_close"
	)
	overview_camera.recenter.connect(func(center): recenter.emit(center))


func _gui_input(event):
	overview_camera._input(event)


func init_overview_map(map_layer_name: String):
	var geo_raster_renderer = subviewport_container.get_node("SubViewport/OverviewRenderer")

	# Duplicate resource otherwise it will be shares properties with
	# other rasterlayers and will get influenced by its behaviour
	geo_raster_renderer.get_node("TexturePlane").mesh = geo_raster_renderer.get_node("TexturePlane").mesh.duplicate()
	
	# Manually set the renderers raster layer
	var map_layer = Layers.get_geo_layer_by_name(map_layer_name)
	geo_raster_renderer.geo_raster_layer = map_layer
	
	# Obtain metadata for correctly loading the full extent of the layer
	var center = Vector2(map_layer.get_center().x, map_layer.get_center().z)
	var extent = map_layer.get_extent().size
	var zoom = Vector2(overview_camera.get_viewport().size) / abs(extent)
	
	# Minimum of zoom vector -> the smaller the zoom the more will be rendered
	var zoom_factor = min(zoom.x, zoom.y)
	zoom = Vector2(zoom_factor, zoom_factor)
	
	# Set metadata
	overview_camera.zoom = zoom
	geo_raster_renderer.center = center
	geo_raster_renderer.zoom = zoom
	geo_raster_renderer.viewport_size = overview_camera.get_viewport().size
	
	# Manually load
	geo_raster_renderer.load_new_data()
	geo_raster_renderer.apply_new_data()
