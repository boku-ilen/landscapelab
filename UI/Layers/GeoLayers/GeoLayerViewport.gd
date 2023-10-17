extends SubViewportContainer

@export var geo_layer_ui: NodePath


func _gui_input(event):
	$SubViewport/Camera2D.input(event)


func _ready():
	$ZoomContainer/ZoomIn.pressed.connect($SubViewport/Camera2D.do_zoom.bind(1.1))
	$ZoomContainer/ZoomOut.pressed.connect($SubViewport/Camera2D.do_zoom.bind(0.9))
	get_node(geo_layer_ui).get_node("ItemList").z_index_changed.connect(
		$SubViewport/GeoLayerRenderers.reclassify_z_indices)
	get_node(geo_layer_ui).get_node("ItemList").geolayer_visibility_changed.connect(
		$SubViewport/GeoLayerRenderers.set_layer_visibility
	)
