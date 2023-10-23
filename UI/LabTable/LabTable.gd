extends Control


@export var geo_layers: Node2D


func _ready():
	$LLConfigSetup.applied_configuration.connect(geo_layers.setup)
	$Button.toggled.connect(set_workshop_mode)
	#geo_layers.center_changed.connect(func(new_center):
	#	$GeoLayerUi/GeoLayerViewport/Node/Labl.text = var_to_str(new_center)
	#)
	
	$LLConfigSetup.setup()


func set_workshop_mode(active: bool): 
	var action_handler = $SubViewportContainer/ActionHandler
	if not active: 
		action_handler.current_action = null
		return
	
	var primary_func = func(event, cursor, state_dict):
		var feature_layer: GeoFeatureLayer = Layers.get_geo_layer_by_name("windturbines")
		var feature: GeoPoint = feature_layer.create_feature()
		feature.set_offset_vector3(
			Vector3(cursor.global_position.x, 0, cursor.global_position.y), 
			geo_layers.current_center.x, 0, geo_layers.current_center.y)
	
	var edit_action = EditingAction.new(primary_func)
	action_handler.set_current_action(edit_action)
