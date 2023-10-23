extends VBoxContainer


@export var shift_coordinates_x := 500
@export var shift_coordinates_y := 500

@export var camera_2d: Camera2D : 
	set(new_camera_2d):
		camera_2d = new_camera_2d
		$VBox/HBox/ZoomContainer.camera_2d = new_camera_2d
		
		$VBox/HBox/GridContainer/Right.pressed.connect(func(): 
			camera_2d.add_offset_and_emit(Vector2(shift_coordinates_x, 0)))
		$VBox/HBox/GridContainer/Left.pressed.connect(func(): 
			camera_2d.add_offset_and_emit(Vector2(-shift_coordinates_x, 0)))
		$VBox/HBox/GridContainer/Up.pressed.connect(func():
			camera_2d.add_offset_and_emit(Vector2(0, -shift_coordinates_y)))
		$VBox/HBox/GridContainer/Down.pressed.connect(func():
			camera_2d.add_offset_and_emit(Vector2(0, shift_coordinates_y)))


@export var map_layer_name: String
@export var configurator: Configurator


func _ready():
	$SetVisible.toggled.connect(func(toggled): $VBox.visible = !toggled)
	configurator.applied_configuration.connect(_init_overview_map)


func _init_overview_map():
	var geo_raster_renderer = $VBox/SubViewportContainer/SubViewport/OverviewRenderer
	var geo_layer_cam = $VBox/SubViewportContainer/SubViewport/Camera2D
	
	geo_raster_renderer.get_node("TexturePlane").mesh = geo_raster_renderer.get_node("TexturePlane").mesh.duplicate()
	geo_raster_renderer.geo_raster_layer = Layers.get_geo_layer_by_name(map_layer_name)
	var center = Vector2(
		geo_raster_renderer.geo_raster_layer.get_center().x, 
		geo_raster_renderer.geo_raster_layer.get_center().z)
	var extent = geo_raster_renderer.geo_raster_layer.get_extent()
	extent = extent.position - extent.end
	var zoom = abs(geo_raster_renderer.viewport_size / extent)
	var zoom_factor = max(zoom.x, zoom.y)
	geo_raster_renderer.center = center
	geo_layer_cam.zoom = Vector2(zoom_factor, zoom_factor)
	geo_raster_renderer.zoom = Vector2(zoom_factor, zoom_factor)
	geo_raster_renderer.viewport_size = $VBox/SubViewportContainer/SubViewport.size
	
	geo_raster_renderer.load_new_data()
	geo_raster_renderer.apply_new_data()
