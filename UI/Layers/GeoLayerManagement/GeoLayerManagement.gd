extends HBoxContainer


@export var action_handler_paths: Array[NodePath]
@export_node_path("ItemList") var geo_layer_list_path
@onready var geo_layer_list: ItemList = get_node(geo_layer_list_path)


func _ready():
	$GeoFeatureLayerManagement.set_buttons_active(false)
	$GeoRasterLayerManagement.set_buttons_active(false)
	
	geo_layer_list.item_selected.connect(
		func(idx): _on_geo_layer_selected(geo_layer_list.get_item_metadata(idx))
	)
	
	_connect_button_with_action(
		$GeoFeatureLayerManagement/Add, 
		func():
			var cls_feature: GeoFeature = $GeoFeatureLayerManagement.geo_feature_layer.create_feature()
			return $GeoFeatureLayerManagement.add_actions[cls_feature.get_class()]
	)
	_connect_button_with_action(
		$GeoRasterLayerManagement/TerraForm,
		func(): return $GeoRasterLayerManagement.terra_form_action
	)
	_connect_button_with_action(
		$GeoRasterLayerManagement/Paint,
		func(): return $GeoRasterLayerManagement.paint_action
	)


# Connects a buttons toggle with a desired action in all action handlers
func _connect_button_with_action(button: BaseButton, get_action: Callable):
	for handler in action_handler_paths.map(func(path): return get_node(path)):
		var action_handler: ActionHandler = handler
		button.toggled.connect(func(toggled: bool):
			if toggled: action_handler.set_current_action(get_action.call())
			else: action_handler.stop_current_action()
		)


func _on_geo_layer_selected(geo_layer):
	if geo_layer is GeoFeatureLayer:
		$GeoFeatureLayerManagement.geo_feature_layer = geo_layer
		$GeoFeatureLayerManagement.set_buttons_active(true)
		$GeoRasterLayerManagement.geo_raster_layer = null
		$GeoRasterLayerManagement.set_buttons_active(false)
	elif geo_layer is GeoRasterLayer:
		$GeoRasterLayerManagement.geo_raster_layer = geo_layer
		$GeoRasterLayerManagement.set_buttons_active(true)
		$GeoFeatureLayerManagement.geo_feature_layer = null
		$GeoFeatureLayerManagement.set_buttons_active(false)
	if not geo_layer.get_dataset().has_write_access():
		$GeoFeatureLayerManagement.set_buttons_active(false)
		$GeoRasterLayerManagement.set_buttons_active(false)
