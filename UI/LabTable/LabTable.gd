extends Control


@export var geo_layers: Node2D


func _ready():
	# FIXME: this will probably removed/rewritten in a later step
	$LLConfigSetup.applied_configuration.connect(geo_layers.setup)
	$Button.toggled.connect(set_workshop_mode)
	$LLConfigSetup.setup()
	
	# Display camera extent on overview
	var extent_visualizer = $SubViewportContainer/PanelContainer/ControlContainer/VBox/SubViewportContainer/SubViewport/ReferenceRect
	geo_layers.camera_extent_changed.connect(func(camera_extent):
		extent_visualizer.position = camera_extent.center - extent_visualizer.size / 2
		extent_visualizer.size = camera_extent.extent)
	
	# Use input on overview map as "recenter"
	$SubViewportContainer/PanelContainer/ControlContainer.recenter.connect(func(center):
		$SubViewportContainer/SubViewport/Camera2D.set_offset_and_emit(center))


func set_workshop_mode(active: bool): 
	var action_handler = $SubViewportContainer/ActionHandler
	if not active: 
		action_handler.current_action = null
		return
	
	var primary_func = func(event, cursor, state_dict):
		var feature_layer: GeoFeatureLayer = Layers.get_geo_layer_by_name("WINDTURBINES")
		var feature: GeoPoint = feature_layer.create_feature()
		feature.set_offset_vector3(
			Vector3(cursor.global_position.x, 0, cursor.global_position.y), 
			geo_layers.center.x, 0, geo_layers.center.y)
	
	var edit_action = EditingAction.new(primary_func)
	action_handler.set_current_action(edit_action)
